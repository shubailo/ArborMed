"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DebugController = void 0;
const db_1 = require("../db");
class DebugController {
    static isAdmin(req) {
        // NODE_ENV !== 'production' check
        const isDev = process.env.NODE_ENV !== 'production';
        // X-ADMIN-KEY check
        const adminKey = req.headers['x-admin-key'];
        const validKey = process.env.DEBUG_API_KEY || 'default_debug_key';
        // Also check if it's localhost (optional but recommended by user)
        const isLocal = req.hostname === 'localhost' || req.hostname === '127.0.0.1';
        return (isDev || isLocal) && (adminKey === validKey);
    }
    static async getEngineDecisions(req, res) {
        if (!DebugController.isAdmin(req)) {
            return res.status(403).json({ error: 'Unauthorized debug access' });
        }
        const { courseId, from, to } = req.query;
        try {
            const logs = await db_1.prisma.engineDecisionLog.findMany({
                where: {
                    courseId: courseId || undefined,
                    createdAt: {
                        gte: from ? new Date(from) : undefined,
                        lte: to ? new Date(to) : undefined,
                    }
                },
                orderBy: { createdAt: 'desc' },
                take: 500 // Limit for safety
            });
            res.json(logs);
        }
        catch (error) {
            res.status(500).json({ error: 'Failed to fetch engine decisions' });
        }
    }
    static async getStudySessions(req, res) {
        if (!DebugController.isAdmin(req)) {
            return res.status(403).json({ error: 'Unauthorized debug access' });
        }
        const { courseId } = req.query;
        try {
            const sessions = await db_1.prisma.studySession.findMany({
                where: {
                    courseId: courseId || undefined
                },
                orderBy: { lastActivityAt: 'desc' },
                take: 500
            });
            res.json(sessions);
        }
        catch (error) {
            res.status(500).json({ error: 'Failed to fetch study sessions' });
        }
    }
}
exports.DebugController = DebugController;
