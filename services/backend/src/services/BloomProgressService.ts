import prisma from '../db';

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
                currentBloomLevel = Math.min(4, currentBloomLevel + 1); // max 4
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
}
