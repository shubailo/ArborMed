import { Question, UserMastery, AnswerOption } from '@medbuddy/shared-types';
import prisma from '../db';
import * as fs from 'fs';
import * as path from 'path';
import { BloomProgressService } from './BloomProgressService';

export type QuestionWithPayload = Question & { options: AnswerOption[] };

export class AdaptiveEngineService {

    private coursesConfig: any[]; // Config objects from JSON

    constructor() {
        const configPath = path.join(__dirname, '..', 'config', 'courses-and-topics.json');
        this.coursesConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    }

    private getTopicsForCourse(courseId: string, orgId: string): string[] {
        const course = this.coursesConfig.find(c => c.id === courseId && c.organizationId === orgId);
        if (!course) return [];
        return course.topics.map((t: any) => t.id);
    }

    /**
     * SM-2 Algorithm
     * quality: 0-5
     */
    calculateNextReview(mastery: UserMastery, quality: number): Partial<UserMastery> {
        let { easiness, interval, repetitions } = mastery;

        if (quality >= 3) {
            if (repetitions === 0) interval = 1;
            else if (repetitions === 1) interval = 6;
            else interval = Math.round(interval * easiness);
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

    async getNextQuestion(userId: string, orgId: string, courseId?: string): Promise<QuestionWithPayload | null> {
        const now = new Date();

        let bloomLevel = 1;
        let topicIds: string[] | undefined = undefined;

        if (courseId) {
            const progress = await (prisma as any).userCourseProgress.findUnique({
                where: { userId_courseId: { userId, courseId } }
            });
            if (progress) {
                bloomLevel = progress.currentBloomLevel;
            }
            const topics = this.getTopicsForCourse(courseId, orgId);
            if (topics.length > 0) {
                topicIds = topics;
            }
        }

        // 1. Check for due questions (Review)
        const dueQuestionsQuery: any = {
            userId,
            organizationId: orgId,
            nextReview: { lte: now },
            question: { status: 'PUBLISHED' }
        };

        if (topicIds) {
            dueQuestionsQuery.question.topicId = { in: topicIds };
        }

        const dueQuestions = await prisma.userMastery.findMany({
            where: dueQuestionsQuery,
            include: { question: { include: { options: true } } },
            take: 10
        }) as any[];

        // 2. Decide: Review vs New
        const isReviewTime = dueQuestions.length > 0 && Math.random() < 0.7;

        if (isReviewTime) {
            const randomReview = dueQuestions[Math.floor(Math.random() * dueQuestions.length)];
            return randomReview.question;
        }

        // 3. Fetch New Questions (not in UserMastery yet)
        const newQuestionsQuery: any = {
            organizationId: orgId,
            status: 'PUBLISHED',
            masteries: { none: { userId } }
        };

        if (topicIds) {
            newQuestionsQuery.topicId = { in: topicIds };
            newQuestionsQuery.bloomLevel = { lte: bloomLevel };
        }

        const newQuestions = await prisma.question.findMany({
            where: newQuestionsQuery,
            include: { options: true },
            take: 10
        }) as unknown as QuestionWithPayload[];

        if (newQuestions.length > 0) {
            newQuestions.sort((a, b) => b.bloomLevel - a.bloomLevel);
            const topCandidates = newQuestions.filter(q => q.bloomLevel === newQuestions[0].bloomLevel);
            return topCandidates[Math.floor(Math.random() * topCandidates.length)];
        }

        // 4. Fallback
        const fallbackQuery: any = {
            organizationId: orgId,
            status: 'PUBLISHED'
        };
        if (topicIds) {
            fallbackQuery.topicId = { in: topicIds };
        }

        return await prisma.question.findFirst({
            where: fallbackQuery,
            include: { options: true }
        }) as unknown as QuestionWithPayload | null;
    }

    async processResult(userId: string, questionId: string, quality: number, courseId?: string, orgId?: string): Promise<void> {
        console.log(`Processing result for ${userId} on ${questionId} with quality ${quality}`);

        // Ha tudjuk a courseId-t és az orgId-t (vagy letöltjük a question-ből), frissítsük a Bloom Progression-t is
        if (courseId && orgId) {
            const isCorrect = quality >= 3;
            await BloomProgressService.updateProgress(userId, courseId, orgId, isCorrect);
        }
    }
}
