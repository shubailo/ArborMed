import { Question, UserMastery, AnswerOption } from '@medbuddy/shared-types';
import { prisma } from '../db';
import * as fs from 'fs';
import * as path from 'path';
import { BloomProgressService } from './BloomProgressService';
import { StudySessionService } from './StudySessionService';

export type QuestionWithPayload = Question & { options: AnswerOption[]; selectionReason?: string };

export class AdaptiveEngineService {

    private coursesConfig: any[]; // Config objects from JSON

    private static readonly TARGET_RETENTION_MIN = 0.85;
    private static readonly TARGET_RETENTION_MAX = 0.90;
    private static readonly LOW_BLOOM_MASTERY_THRESHOLD = 0.65;
    private static readonly HIGH_BLOOM_ALLOWED_THRESHOLD = 0.75;

    private readonly strategyVariant: string;

    constructor() {
        this.strategyVariant = process.env.ENGINE_STRATEGY_VARIANT || "M6_default";
        const configPath = path.join(__dirname, '..', 'config', 'courses-and-topics.json');
        this.coursesConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    }

    private async calculateRetention(userId: string): Promise<number> {
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        // Try last 7 days first
        let events = await prisma.studyEvent.findMany({
            where: {
                userId,
                createdAt: { gte: sevenDaysAgo }
            },
            take: 100
        });

        // Fallback to last 50 events if 7 days has too few
        if (events.length < 20) {
            events = await prisma.studyEvent.findMany({
                where: { userId },
                orderBy: { createdAt: 'desc' },
                take: 50
            });
        }

        if (events.length === 0) return 0.87; // Neutral default (middle of target)

        const corrects = events.filter(e => e.isCorrect).length;
        return corrects / events.length;
    }

    private getTopicsForCourse(courseId: string, orgId: string): string[] {
        const course = this.coursesConfig.find(c => c.id === courseId && c.organizationId === orgId);
        if (!course) return [];
        return course.topics.map((t: any) => t.id);
    }

    /**
     * SM-2 Algorithm with Retention Tuning
     * quality: 0-5
     */
    async calculateNextReview(userId: string, mastery: UserMastery, quality: number): Promise<Partial<UserMastery>> {
        let { easiness, interval, repetitions } = mastery;
        const retention = await this.calculateRetention(userId);

        if (quality >= 3) {
            if (repetitions === 0) interval = 1;
            else if (repetitions === 1) interval = 6;
            else {
                // Retention-aware interval tuning
                let modifier = 1.0;
                if (retention < AdaptiveEngineService.TARGET_RETENTION_MIN) {
                    modifier = 0.85; // Too many mistakes -> slow down
                } else if (retention > AdaptiveEngineService.TARGET_RETENTION_MAX) {
                    modifier = 1.15; // Too many correct -> speed up
                }
                interval = Math.round(interval * easiness * modifier);
            }
            repetitions++;
        } else {
            repetitions = 0;
            interval = 1;
        }

        easiness = easiness + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
        if (easiness < 1.3) easiness = 1.3;

        const nextDate = new Date();
        nextDate.setDate(nextDate.getDate() + interval);

        return {
            easiness,
            interval,
            repetitions,
            nextReview: nextDate.toISOString()
        };
    }

    async getNextQuestion(userId: string, orgId: string, courseId?: string, topicId?: string): Promise<QuestionWithPayload | null> {
        const now = new Date();
        let topicIds: string[] | undefined = undefined;

        // Ensure session tracking (implicit)
        let sessionId: string | null = null;
        if (courseId) {
            try {
                sessionId = await StudySessionService.getOrCreateSession(userId, courseId);
            } catch (err) {
                console.error('[AdaptiveEngine] Failed to get/create session:', err);
            }
        }

        if (courseId) {
            const topics = this.getTopicsForCourse(courseId, orgId);
            if (topics.length > 0) topicIds = topics;
        }

        // 1. Check for due questions (Review)
        const dueQuestions = await prisma.userMastery.findMany({
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
            } as QuestionWithPayload;
        }

        // 3. Bloom-aware "New" Question Selection
        const masteries = await prisma.userBloomMastery.findMany({
            where: {
                userId,
                topicId: topicIds ? { in: topicIds } : undefined
            }
        });

        let targetTopicId: string | undefined = topicIds?.[0];
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

        const newQuestions = await prisma.question.findMany({
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
            } as QuestionWithPayload;
        }

        // 4. Fallback
        const fallback = await prisma.question.findFirst({
            where: {
                organizationId: orgId,
                status: 'PUBLISHED'
            },
            include: { options: true }
        }) as unknown as QuestionWithPayload | null;

        if (fallback) {
            fallback.selectionReason = "Continuous practice: Exploring available questions to maintain learning momentum.";
        }

        // Non-blocking decision logging
        const selectedQuestion = isReviewTime ? {
            ... (dueQuestions[Math.floor(Math.random() * dueQuestions.length)].question),
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

        return selectedQuestion as QuestionWithPayload;
    }

    private async logDecision(userId: string, courseId: string | undefined, topicId: string | undefined, questionId: string, bloomLevel: number, difficulty: number, reason: string | undefined) {
        try {
            await prisma.engineDecisionLog.create({
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
        } catch (error) {
            console.error('[AdaptiveEngine] Error writing decision log:', error);
        }
    }

    async processResult(userId: string, questionId: string, quality: number, courseId?: string, orgId?: string): Promise<void> {
        console.log(`Processing result for ${userId} on ${questionId} with quality ${quality}`);

        const question = await prisma.question.findUnique({
            where: { id: questionId },
            include: { topic: true }
        });
        if (!question) return;

        const isCorrect = quality >= 3;

        // 1. Log Study Event with metadata
        await prisma.studyEvent.create({
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
        let mastery = await prisma.userMastery.findUnique({
            where: { userId_questionId: { userId, questionId } }
        });

        if (!mastery) {
            mastery = await prisma.userMastery.create({
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

        const updates = await this.calculateNextReview(userId, mastery as unknown as UserMastery, quality);
        await prisma.userMastery.update({
            where: { userId_questionId: { userId, questionId } },
            data: {
                easiness: updates.easiness,
                interval: updates.interval,
                repetitions: updates.repetitions,
                nextReview: new Date(updates.nextReview as string)
            }
        });

        // 3. Update UserBloomMastery (Topic + Bloom level)
        await BloomProgressService.updateBloomMasteryScore(userId, question.topicId, question.bloomLevel, isCorrect);

        // 4. Update Course Progress (Bloom Progression)
        if (courseId && orgId) {
            await BloomProgressService.updateProgress(userId, courseId, orgId, isCorrect);
        }

        // 5. Update Study Session (Non-blocking)
        if (courseId) {
            StudySessionService.getOrCreateSession(userId, courseId)
                .then(sid => StudySessionService.incrementQuestionCount(sid))
                .catch(err => console.error('[AdaptiveEngine] Session update failed:', err));
        }
    }
}
