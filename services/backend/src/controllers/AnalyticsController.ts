import { Request, Response } from 'express';
import prisma from '../db';
import { calculateReadinessScore } from '../services/AnalyticsService';

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
            correctnessRate: "78%",
            students,
            weakTopics: [
                { id: "erythrocyte-disorders", name: "Erythrocyte Disorders", score: 1.2 },
                { id: "coagulation-basics", name: "Coagulation Basics", score: 1.5 }
            ]
        });
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
}
