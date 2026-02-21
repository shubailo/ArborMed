import { prisma } from '../db';

export class StudySessionService {
    private static readonly SESSION_TIMEOUT_MS = 20 * 60 * 1000; // 20 minutes

    /**
     * Finds an active session or creates a new one.
     */
    static async getOrCreateSession(userId: string, courseId: string, mode: string = 'NORMAL'): Promise<string> {
        const now = new Date();
        const timeoutThreshold = new Date(now.getTime() - this.SESSION_TIMEOUT_MS);

        // Find the most recent session for this user/course that hasn't timed out
        const activeSession = await prisma.studySession.findFirst({
            where: {
                userId,
                courseId,
                mode,
                endedAt: null,
                lastActivityAt: { gte: timeoutThreshold }
            },
            orderBy: { lastActivityAt: 'desc' }
        });

        if (activeSession) {
            // Update last activity to keep it alive
            await prisma.studySession.update({
                where: { id: activeSession.id },
                data: { lastActivityAt: now }
            });
            return activeSession.id;
        }

        const newSession = await prisma.studySession.create({
            data: {
                userId,
                courseId,
                mode,
                startedAt: now,
                lastActivityAt: now,
                questionCount: 0
            }
        });
        return newSession.id;
    }

    /**
     * Increments the question count and updates activity timestamp.
     */
    static async incrementQuestionCount(sessionId: string): Promise<void> {
        // Non-blocking approach: we don't await this in the main flow if possible, 
        // or wrap in try-catch to ensure failure doesn't break study.
        try {
            await prisma.studySession.update({
                where: { id: sessionId },
                data: {
                    questionCount: { increment: 1 },
                    lastActivityAt: new Date()
                }
            });
        } catch (error) {
            console.error('[StudySessionService] Error incrementing question count:', error);
        }
    }

    /**
     * Optional explicit end (as per user request: timeout handles it, but helper is useful)
     */
    static async endSession(sessionId: string): Promise<void> {
        try {
            await prisma.studySession.update({
                where: { id: sessionId },
                data: { endedAt: new Date() }
            });
        } catch (error) {
            console.error('[StudySessionService] Error ending session:', error);
        }
    }
}
