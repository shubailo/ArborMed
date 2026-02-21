"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.StudySessionService = void 0;
const db_1 = require("../db");
class StudySessionService {
    static SESSION_TIMEOUT_MS = 20 * 60 * 1000; // 20 minutes
    /**
     * Finds an active session or creates a new one.
     */
    static async getOrCreateSession(userId, courseId) {
        const now = new Date();
        const timeoutThreshold = new Date(now.getTime() - this.SESSION_TIMEOUT_MS);
        // Find the most recent session for this user/course that hasn't timed out
        const activeSession = await db_1.prisma.studySession.findFirst({
            where: {
                userId,
                courseId,
                endedAt: null,
                lastActivityAt: { gte: timeoutThreshold }
            },
            orderBy: { lastActivityAt: 'desc' }
        });
        if (activeSession) {
            // Update last activity to keep it alive
            await db_1.prisma.studySession.update({
                where: { id: activeSession.id },
                data: { lastActivityAt: now }
            });
            return activeSession.id;
        }
        // No active session, create a new one
        const newSession = await db_1.prisma.studySession.create({
            data: {
                userId,
                courseId,
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
    static async incrementQuestionCount(sessionId) {
        // Non-blocking approach: we don't await this in the main flow if possible, 
        // or wrap in try-catch to ensure failure doesn't break study.
        try {
            await db_1.prisma.studySession.update({
                where: { id: sessionId },
                data: {
                    questionCount: { increment: 1 },
                    lastActivityAt: new Date()
                }
            });
        }
        catch (error) {
            console.error('[StudySessionService] Error incrementing question count:', error);
        }
    }
    /**
     * Optional explicit end (as per user request: timeout handles it, but helper is useful)
     */
    static async endSession(sessionId) {
        try {
            await db_1.prisma.studySession.update({
                where: { id: sessionId },
                data: { endedAt: new Date() }
            });
        }
        catch (error) {
            console.error('[StudySessionService] Error ending session:', error);
        }
    }
}
exports.StudySessionService = StudySessionService;
