"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdaptiveEngineService = void 0;
const db_1 = require("../db");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const BloomProgressService_1 = require("./BloomProgressService");
const StudySessionService_1 = require("./StudySessionService");
class AdaptiveEngineService {
    coursesConfig; // Config objects from JSON
    static TARGET_RETENTION_MIN = 0.85;
    static TARGET_RETENTION_MAX = 0.90;
    static LOW_BLOOM_MASTERY_THRESHOLD = 0.65;
    static HIGH_BLOOM_ALLOWED_THRESHOLD = 0.75;
    strategyVariant;
    constructor() {
        this.strategyVariant = process.env.ENGINE_STRATEGY_VARIANT || "M6_default";
        const configPath = path.join(__dirname, '..', 'config', 'courses-and-topics.json');
        this.coursesConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    }
    async calculateRetention(userId) {
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        // Try last 7 days first
        let events = await db_1.prisma.studyEvent.findMany({
            where: {
                userId,
                createdAt: { gte: sevenDaysAgo }
            },
            take: 100
        });
        // Fallback to last 50 events if 7 days has too few
        if (events.length < 20) {
            events = await db_1.prisma.studyEvent.findMany({
                where: { userId },
                orderBy: { createdAt: 'desc' },
                take: 50
            });
        }
        if (events.length === 0)
            return 0.87; // Neutral default (middle of target)
        const corrects = events.filter(e => e.isCorrect).length;
        return corrects / events.length;
    }
    getTopicsForCourse(courseId, orgId) {
        const course = this.coursesConfig.find(c => c.id === courseId && c.organizationId === orgId);
        if (!course)
            return [];
        return course.topics.map((t) => t.id);
    }
    /**
     * SM-2 Algorithm with Retention Tuning
     * quality: 0-5
     */
    async calculateNextReview(userId, mastery, quality) {
        let { easiness, interval, repetitions } = mastery;
        const retention = await this.calculateRetention(userId);
        if (quality >= 3) {
            if (repetitions === 0)
                interval = 1;
            else if (repetitions === 1)
                interval = 6;
            else {
                // Retention-aware interval tuning
                let modifier = 1.0;
                if (retention < AdaptiveEngineService.TARGET_RETENTION_MIN) {
                    modifier = 0.85; // Too many mistakes -> slow down
                }
                else if (retention > AdaptiveEngineService.TARGET_RETENTION_MAX) {
                    modifier = 1.15; // Too many correct -> speed up
                }
                interval = Math.round(interval * easiness * modifier);
            }
            repetitions++;
        }
        else {
            repetitions = 0;
            interval = 1;
        }
        easiness = easiness + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
        if (easiness < 1.3)
            easiness = 1.3;
        const nextDate = new Date();
        nextDate.setDate(nextDate.getDate() + interval);
        return {
            easiness,
            interval,
            repetitions,
            nextReview: nextDate.toISOString()
        };
    }
    async getNextQuestion(userId, orgId, courseId, topicId) {
        const now = new Date();
        let topicIds = undefined;
        // Ensure session tracking (implicit)
        let sessionId = null;
        if (courseId) {
            try {
                sessionId = await StudySessionService_1.StudySessionService.getOrCreateSession(userId, courseId);
            }
            catch (err) {
                console.error('[AdaptiveEngine] Failed to get/create session:', err);
            }
        }
        if (courseId) {
            const topics = this.getTopicsForCourse(courseId, orgId);
            if (topics.length > 0)
                topicIds = topics;
        }
        // 1. Check for due questions (Review)
        const dueQuestions = await db_1.prisma.userMastery.findMany({
            where: {
                userId,
                organizationId: orgId,
                nextReview: { lte: now },
                question: {
                    status: 'PUBLISHED',
                    topicId: topicIds ? { in: topicIds } : undefined
                }
            },
            include: { question: { include: { options: true } } },
            take: 10
        });
        // 2. Decide: Review vs New
        const isReviewTime = dueQuestions.length > 0 && Math.random() < 0.7;
        if (isReviewTime) {
            const randomReview = dueQuestions[Math.floor(Math.random() * dueQuestions.length)];
            return {
                ...randomReview.question,
                selectionReason: "Spaced repetition: This question is due for review to strengthen your long-term memory."
            };
        }
        // 3. Bloom-aware "New" Question Selection
        const masteries = await db_1.prisma.userBloomMastery.findMany({
            where: {
                userId,
                topicId: topicIds ? { in: topicIds } : undefined
            }
        });
        let targetTopicId = topicIds?.[0];
        let targetBloomLevel = 1;
        if (topicIds && topicIds.length > 0) {
            const topicFocus = topicIds.map(tid => {
                const topicLevels = masteries.filter(m => m.topicId === tid);
                for (let b = 1; b <= 6; b++) {
                    const m = topicLevels.find(l => l.bloomLevel === b);
                    if (!m || m.masteryScore < AdaptiveEngineService.LOW_BLOOM_MASTERY_THRESHOLD * 100) {
                        return { topicId: tid, bloomLevel: b, priority: 10 - b };
                    }
                }
                return { topicId: tid, bloomLevel: 6, priority: 0 };
            });
            topicFocus.sort((a, b) => b.priority - a.priority);
            targetTopicId = topicFocus[0].topicId;
            targetBloomLevel = topicFocus[0].bloomLevel;
        }
        const newQuestions = await db_1.prisma.question.findMany({
            where: {
                organizationId: orgId,
                status: 'PUBLISHED',
                topicId: targetTopicId,
                bloomLevel: targetBloomLevel,
                masteries: { none: { userId } }
            },
            include: { options: true },
            take: 20
        });
        if (newQuestions.length > 0) {
            const topicMastery = masteries.find(m => m.topicId === targetTopicId && m.bloomLevel === targetBloomLevel);
            const score = topicMastery?.masteryScore || 0;
            const sortedQuestions = [...newQuestions].sort((a, b) => {
                const weight = score > 50 ? 3 : 1;
                return Math.abs((a.difficulty || 1) - weight) - Math.abs((b.difficulty || 1) - weight);
            });
            const bloomNames = ["", "Remember", "Understand", "Apply", "Analyze", "Evaluate", "Create"];
            return {
                ...sortedQuestions[0],
                selectionReason: `Pedagogical progression: Focusing on the ${bloomNames[targetBloomLevel]} level in this topic to build your foundation.`
            };
        }
        // 4. Fallback
        const fallback = await db_1.prisma.question.findFirst({
            where: {
                organizationId: orgId,
                status: 'PUBLISHED'
            },
            include: { options: true }
        });
        if (fallback) {
            fallback.selectionReason = "Continuous practice: Exploring available questions to maintain learning momentum.";
        }
        // Non-blocking decision logging
        const selectedQuestion = isReviewTime ? {
            ...(dueQuestions[Math.floor(Math.random() * dueQuestions.length)].question),
            selectionReason: "Spaced repetition: This question is due for review to strengthen your long-term memory."
        } : (newQuestions.length > 0 ? {
            ...([...newQuestions].sort((a, b) => {
                const topicMastery = masteries.find(m => m.topicId === targetTopicId && m.bloomLevel === targetBloomLevel);
                const score = topicMastery?.masteryScore || 0;
                const weight = score > 50 ? 3 : 1;
                return Math.abs((a.difficulty || 1) - weight) - Math.abs((b.difficulty || 1) - weight);
            })[0]),
            selectionReason: `Pedagogical progression: Focusing on the ${["", "Remember", "Understand", "Apply", "Analyze", "Evaluate", "Create"][targetBloomLevel]} level in this topic to build your foundation.`
        } : fallback);
        if (selectedQuestion) {
            this.logDecision(userId, courseId, targetTopicId, selectedQuestion.id, selectedQuestion.bloomLevel, selectedQuestion.difficulty, selectedQuestion.selectionReason).catch(err => {
                console.error('[AdaptiveEngine] Decision log failed:', err);
            });
        }
        return selectedQuestion;
    }
    async logDecision(userId, courseId, topicId, questionId, bloomLevel, difficulty, reason) {
        try {
            await db_1.prisma.engineDecisionLog.create({
                data: {
                    userId,
                    courseId,
                    topicId,
                    questionId,
                    bloomLevel,
                    difficulty,
                    selectionReason: reason,
                    strategyVariant: this.strategyVariant
                }
            });
        }
        catch (error) {
            console.error('[AdaptiveEngine] Error writing decision log:', error);
        }
    }
    async processResult(userId, questionId, quality, courseId, orgId) {
        console.log(`Processing result for ${userId} on ${questionId} with quality ${quality}`);
        const question = await db_1.prisma.question.findUnique({
            where: { id: questionId },
            include: { topic: true }
        });
        if (!question)
            return;
        const isCorrect = quality >= 3;
        // 1. Log Study Event with metadata
        await db_1.prisma.studyEvent.create({
            data: {
                userId,
                questionId,
                topicId: question.topicId,
                organizationId: orgId || question.organizationId,
                isCorrect,
                bloomLevel: question.bloomLevel,
                difficulty: question.difficulty,
                responseTimeMs: 0 // Placeholder
            }
        });
        // 2. Update SM-2 Mastery
        let mastery = await db_1.prisma.userMastery.findUnique({
            where: { userId_questionId: { userId, questionId } }
        });
        if (!mastery) {
            mastery = await db_1.prisma.userMastery.create({
                data: {
                    userId,
                    questionId,
                    organizationId: orgId || question.organizationId,
                    easiness: 2.5,
                    interval: 0,
                    repetitions: 0,
                    nextReview: new Date()
                }
            });
        }
        const updates = await this.calculateNextReview(userId, mastery, quality);
        await db_1.prisma.userMastery.update({
            where: { userId_questionId: { userId, questionId } },
            data: {
                easiness: updates.easiness,
                interval: updates.interval,
                repetitions: updates.repetitions,
                nextReview: new Date(updates.nextReview)
            }
        });
        // 3. Update UserBloomMastery (Topic + Bloom level)
        await BloomProgressService_1.BloomProgressService.updateBloomMasteryScore(userId, question.topicId, question.bloomLevel, isCorrect);
        // 4. Update Course Progress (Bloom Progression)
        if (courseId && orgId) {
            await BloomProgressService_1.BloomProgressService.updateProgress(userId, courseId, orgId, isCorrect);
        }
        // 5. Update Study Session (Non-blocking)
        if (courseId) {
            StudySessionService_1.StudySessionService.getOrCreateSession(userId, courseId)
                .then(sid => StudySessionService_1.StudySessionService.incrementQuestionCount(sid))
                .catch(err => console.error('[AdaptiveEngine] Session update failed:', err));
        }
    }
}
exports.AdaptiveEngineService = AdaptiveEngineService;
