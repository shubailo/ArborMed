import { Request, Response } from 'express';
import { prisma } from '../db';

export class DebugController {

    private static isAdmin(req: Request): boolean {
        // NODE_ENV !== 'production' check
        const isDev = process.env.NODE_ENV !== 'production';

        // X-ADMIN-KEY check
        const adminKey = req.headers['x-admin-key'];
        const validKey = process.env.DEBUG_API_KEY || 'default_debug_key';

        // Also check if it's localhost (optional but recommended by user)
        const isLocal = req.hostname === 'localhost' || req.hostname === '127.0.0.1';

        return (isDev || isLocal) && (adminKey === validKey);
    }

    static async getEngineDecisions(req: Request, res: Response) {
        if (!DebugController.isAdmin(req)) {
            return res.status(403).json({ error: 'Unauthorized debug access' });
        }

        const { courseId, from, to } = req.query;

        try {
            const logs = await prisma.engineDecisionLog.findMany({
                where: {
                    courseId: courseId as string || undefined,
                    createdAt: {
                        gte: from ? new Date(from as string) : undefined,
                        lte: to ? new Date(to as string) : undefined,
                    }
                },
                orderBy: { createdAt: 'desc' },
                take: 500 // Limit for safety
            });
            res.json(logs);
        } catch (error) {
            res.status(500).json({ error: 'Failed to fetch engine decisions' });
        }
    }

    static async getStudySessions(req: Request, res: Response) {
        if (!DebugController.isAdmin(req)) {
            return res.status(403).json({ error: 'Unauthorized debug access' });
        }

        const { courseId } = req.query;

        try {
            const sessions = await prisma.studySession.findMany({
                where: {
                    courseId: courseId as string || undefined
                },
                orderBy: { lastActivityAt: 'desc' },
                take: 500
            });
            res.json(sessions);
        } catch (error) {
            res.status(500).json({ error: 'Failed to fetch study sessions' });
        }
    }
}
