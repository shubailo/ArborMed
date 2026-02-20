import { Question, UserMastery } from '@medbuddy/shared-types';
import { PrismaClient } from '@prisma/client';

export class AdaptiveEngineService {
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

    async getNextQuestion(userId: string, orgId: string): Promise<any> {
        const prisma = new PrismaClient();
        const now = new Date();

        // 1. Check for due questions (Review)
        const dueQuestions = await prisma.userMastery.findMany({
            where: {
                userId,
                organizationId: orgId,
                nextReview: { lte: now },
                question: { status: 'PUBLISHED' }
            },
            include: { question: { include: { options: true } } },
            take: 10
        });

        // 2. Decide: Review vs New
        const isReviewTime = dueQuestions.length > 0 && Math.random() < 0.7;

        if (isReviewTime) {
            const randomReview = dueQuestions[Math.floor(Math.random() * dueQuestions.length)];
            return randomReview.question;
        }

        // 3. Fetch New Questions (not in UserMastery yet)
        const newQuestions = await prisma.question.findMany({
            where: {
                organizationId: orgId,
                status: 'PUBLISHED',
                masteries: { none: { userId } }
            },
            include: { options: true },
            take: 10
        });

        if (newQuestions.length > 0) {
            // Pick one randomly for now, ideally weakest topic
            return newQuestions[Math.floor(Math.random() * newQuestions.length)];
        }

        // 4. Fallback: If no new and no due, just give any published question
        const fallback = await prisma.question.findFirst({
            where: { organizationId: orgId, status: 'PUBLISHED' },
            include: { options: true }
        });

        return fallback;
    }

    async processResult(userId: string, questionId: string, quality: number): Promise<void> {
        console.log(`Processing result for ${userId} on ${questionId} with quality ${quality}`);
    }
}
