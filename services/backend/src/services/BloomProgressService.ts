import { prisma } from '../db';

export interface BloomState {
    currentBloomLevel: number;
    streakCorrect: number;
    streakWrong: number;
}

/**
 * Service to manage Bloom Level progression per user, per course.
 */
export class BloomProgressService {
    /**
     * Pure logic function to calculate the new state after an answer.
     * Rules:
     * - Streak of 8 correct answers increases BloomLevel (max 4). Correct answer zeroes streakWrong.
     * - Streak of 5 wrong answers decreases BloomLevel (min 1). Wrong answer zeroes streakCorrect.
     */
    static calculateNewState(currentState: BloomState, isCorrect: boolean): BloomState {
        let { currentBloomLevel, streakCorrect, streakWrong } = currentState;

        if (isCorrect) {
            streakCorrect += 1;
            streakWrong = 0; // helyes válasz nullázza a hibásak streak-jét

            if (streakCorrect >= 8) {
                currentBloomLevel = Math.min(6, currentBloomLevel + 1); // max 6
                streakCorrect = 0; // nullázza a streak-et, hogy újra induljon a számláló
            }
        } else {
            streakWrong += 1;
            streakCorrect = 0; // hibás válasz nullázza a helyesek streak-jét

            if (streakWrong >= 5) {
                currentBloomLevel = Math.max(1, currentBloomLevel - 1); // min 1
                streakWrong = 0;
            }
        }

        return { currentBloomLevel, streakCorrect, streakWrong };
    }

    /**
     * Updates the progress state of the user for a specific course in the database.
     */
    static async updateProgress(
        userId: string,
        courseId: string,
        orgId: string,
        isCorrect: boolean
    ) {
        let progress = await prisma.userCourseProgress.findUnique({
            where: {
                userId_courseId: { userId, courseId }
            }
        });

        if (!progress) {
            progress = await prisma.userCourseProgress.create({
                data: {
                    userId,
                    courseId,
                    organizationId: orgId,
                    currentBloomLevel: 1,
                    streakCorrect: 0,
                    streakWrong: 0,
                }
            });
        }

        const newState = this.calculateNewState({
            currentBloomLevel: progress.currentBloomLevel,
            streakCorrect: progress.streakCorrect,
            streakWrong: progress.streakWrong
        }, isCorrect);

        await prisma.userCourseProgress.update({
            where: {
                userId_courseId: { userId, courseId }
            },
            data: newState
        });

        return newState;
    }

    /**
     * Updates the mastery score for a specific topic and bloom level.
     * Uses a moving average to track progress.
     */
    static async updateBloomMasteryScore(userId: string, topicId: string, bloomLevel: number, isCorrect: boolean) {
        let bloomMastery = await prisma.userBloomMastery.findUnique({
            where: { userId_topicId_bloomLevel: { userId, topicId, bloomLevel } }
        });

        if (!bloomMastery) {
            bloomMastery = await prisma.userBloomMastery.create({
                data: { userId, topicId, bloomLevel, masteryScore: 0 }
            });
        }

        // Simple moving average for mastery score (0-100)
        const weight = 0.2;
        const currentScore = isCorrect ? 100 : 0;
        const newMasteryScore = (bloomMastery.masteryScore * (1 - weight)) + (currentScore * weight);

        await prisma.userBloomMastery.update({
            where: { userId_topicId_bloomLevel: { userId, topicId, bloomLevel } },
            data: { masteryScore: newMasteryScore }
        });

        return newMasteryScore;
    }

    static readonly BLOOM_WEIGHTS: Record<number, number> = {
        1: 1.0,
        2: 1.0,
        3: 1.5,
        4: 1.5,
        5: 2.0,
        6: 2.0,
    };

    static readonly MASTERY_THRESHOLD = 60;

    /**
     * Determines the mastery badge based on bloom level scores.
     * Logic is cumulative: lower levels must be mastered to unlock higher level badges.
     */
    static calculateMasteryBadge(bloomLevels: { bloomLevel: number, masteryScore: number }[]): 'FOUNDATION' | 'APPLICATION' | 'ADVANCED' | 'EXPERT' | 'NONE' {
        const scores: Record<number, number> = {};
        bloomLevels.forEach(b => scores[b.bloomLevel] = b.masteryScore);

        const avg12 = ((scores[1] || 0) + (scores[2] || 0)) / 2;
        const score3 = scores[3] || 0;
        const avg45 = ((scores[4] || 0) + (scores[5] || 0)) / 2;
        const score6 = scores[6] || 0;

        if (score6 >= this.MASTERY_THRESHOLD && avg45 >= this.MASTERY_THRESHOLD && score3 >= this.MASTERY_THRESHOLD && avg12 >= this.MASTERY_THRESHOLD) return 'EXPERT';
        if (avg45 >= this.MASTERY_THRESHOLD && score3 >= this.MASTERY_THRESHOLD && avg12 >= this.MASTERY_THRESHOLD) return 'ADVANCED';
        if (score3 >= this.MASTERY_THRESHOLD && avg12 >= this.MASTERY_THRESHOLD) return 'APPLICATION';
        if (avg12 >= this.MASTERY_THRESHOLD) return 'FOUNDATION';

        return 'NONE';
    }

    /**
     * Calculates weighted average mastery across all bloom levels.
     */
    static calculateWeightedMastery(bloomLevels: { bloomLevel: number, masteryScore: number }[]): number {
        let totalWeightedScore = 0;
        let totalWeight = 0;

        bloomLevels.forEach(b => {
            const weight = this.BLOOM_WEIGHTS[b.bloomLevel] || 1.0;
            totalWeightedScore += (b.masteryScore * weight);
            totalWeight += weight;
        });

        return totalWeight > 0 ? Math.round(totalWeightedScore / totalWeight) : 0;
    }
}
