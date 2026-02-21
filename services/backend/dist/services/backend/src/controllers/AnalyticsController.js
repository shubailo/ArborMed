"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AnalyticsController = void 0;
const db_1 = require("../db");
const AnalyticsService_1 = require("../services/AnalyticsService");
class AnalyticsController {
    async getCourseOverview(req, res) {
        const { courseId } = req.params;
        const users = await db_1.prisma.user.findMany({ where: { organizationId: courseId } });
        let totalReadiness = 0;
        const students = [];
        for (const user of users) {
            const readiness = await (0, AnalyticsService_1.calculateReadinessScore)(user.id, courseId);
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
    async getMasteryOverTime(req, res) {
        const { courseId } = req.params;
        const data = await (0, AnalyticsService_1.getMasteryOverTime)(courseId);
        res.json(data);
    }
    async getTopicBloomBreakdown(req, res) {
        const { courseId } = req.params;
        const data = await (0, AnalyticsService_1.getTopicBloomBreakdown)(courseId);
        res.json(data);
    }
    async getEngagement(req, res) {
        const { courseId } = req.params;
        const data = await (0, AnalyticsService_1.getEngagement)(courseId);
        res.json(data);
    }
    async getRetentionOverTime(req, res) {
        const { courseId } = req.params;
        const data = await (0, AnalyticsService_1.getRetentionOverTime)(courseId);
        res.json(data);
    }
    async getBloomUsageSummary(req, res) {
        const { courseId } = req.params;
        const data = await (0, AnalyticsService_1.getBloomUsageSummary)(courseId);
        res.json(data);
    }
    async getUserOverview(req, res) {
        const { userId } = req.params;
        const stats = await db_1.prisma.userMastery.findMany({
            where: { userId },
        });
        res.json({
            answeredCount: stats.length,
            masteryLevel: stats.length > 0 ? "Intermediate" : "Beginner"
        });
    }
}
exports.AnalyticsController = AnalyticsController;
