import { Request, Response } from 'express';
import { prisma } from '../db';
import { calculateReadinessScore, getMasteryOverTime, getTopicBloomBreakdown, getEngagement, getRetentionOverTime, getBloomUsageSummary } from '../services/AnalyticsService';
import { StudentAnalyticsService } from '../services/StudentAnalyticsService';

export class AnalyticsController {

    async getCourseOverview(req: Request, res: Response): Promise<void> {
        const { courseId } = req.params;

        const users = await prisma.user.findMany({ where: { organizationId: courseId } });
        let totalReadiness = 0;
        const students = [];

        for (const user of users) {
            const readiness = await calculateReadinessScore(user.id, courseId);
            totalReadiness += readiness;
            students.push({
                id: user.id,
                email: user.email,
                readiness,
                risk: readiness < 50
            });
        }

        const avgReadiness = users.length > 0 ? totalReadiness / users.length : 0;

        res.json({
            avgReadiness: Math.round(avgReadiness),
            correctnessRate: "78%", // This could also be calculated dynamically if needed
            students,
            weakTopics: [
                { id: "erythrocyte-disorders", name: "Erythrocyte Disorders", score: 1.2 },
                { id: "coagulation-basics", name: "Coagulation Basics", score: 1.5 }
            ]
        });
    }

    async getMasteryOverTime(req: Request, res: Response): Promise<void> {
        const { courseId } = req.params;
        const data = await getMasteryOverTime(courseId);
        res.json(data);
    }

    async getTopicBloomBreakdown(req: Request, res: Response): Promise<void> {
        const { courseId } = req.params;
        const data = await getTopicBloomBreakdown(courseId);
        res.json(data);
    }

    async getEngagement(req: Request, res: Response): Promise<void> {
        const { courseId } = req.params;
        const data = await getEngagement(courseId);
        res.json(data);
    }

    async getRetentionOverTime(req: Request, res: Response): Promise<void> {
        const { courseId } = req.params;
        const data = await getRetentionOverTime(courseId);
        res.json(data);
    }

    async getBloomUsageSummary(req: Request, res: Response): Promise<void> {
        const { courseId } = req.params;
        const data = await getBloomUsageSummary(courseId);
        res.json(data);
    }

    async getUserOverview(req: Request, res: Response): Promise<void> {
        const { userId } = req.params;
        const stats = await prisma.userMastery.findMany({
            where: { userId },
        });
        res.json({
            answeredCount: stats.length,
            masteryLevel: stats.length > 0 ? "Intermediate" : "Beginner"
        });
    }

    async getActivityTrends(req: Request, res: Response): Promise<void> {
        const { userId, courseId } = req.params;
        const range = req.query.range === '30d' ? '30d' : '7d';

        try {
            const data = await StudentAnalyticsService.getActivityTrends(userId, courseId, range);
            res.json(data);
        } catch (error) {
            console.error('[AnalyticsController] getActivityTrends err:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    async getDailyPrescription(req: Request, res: Response): Promise<void> {
        const { userId, courseId } = req.params;
        const timezoneOffset = parseInt(req.query.timezoneOffset as string) || 0;

        try {
            const data = await StudentAnalyticsService.getDailyPrescription(userId, courseId, timezoneOffset);
            res.json(data);
        } catch (error) {
            console.error('[AnalyticsController] getDailyPrescription err:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
}

