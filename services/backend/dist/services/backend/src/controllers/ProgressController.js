"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProgressController = void 0;
const db_1 = require("../db");
const BloomProgressService_1 = require("../services/BloomProgressService");
class ProgressController {
    getUserCourseProgress = async (req, res) => {
        const { userId, courseId } = req.params;
        const user = req.user;
        if (!user) {
            console.error('[ProgressController] ERROR: User undefined in getUserCourseProgress');
            res.status(401).json({ error: 'Authentication required' });
            return;
        }
        const organizationId = user.organizationId;
        try {
            // 1. Get all topics for this course from config
            const projectsPath = require('path').join(__dirname, '..', 'config', 'courses-and-topics.json');
            const coursesConfig = require('fs').readFileSync(projectsPath, 'utf8');
            const courses = JSON.parse(coursesConfig);
            const course = courses.find((c) => c.id === courseId && c.organizationId === organizationId);
            if (!course) {
                res.status(404).json({ error: 'Course not found' });
                return;
            }
            const topicIds = course.topics.map((t) => t.id);
            // 2. Fetch all UserBloomMastery records for these topics
            const bloomMasteries = await db_1.prisma.userBloomMastery.findMany({
                where: {
                    userId,
                    topicId: { in: topicIds }
                }
            });
            // 3. Map to DTOs
            const topicProgressDtos = course.topics.map((topic) => {
                const topicBloomLevels = bloomMasteries.filter(bm => bm.topicId === topic.id);
                const bloomLevelStates = [];
                for (let i = 1; i <= 6; i++) {
                    const bm = topicBloomLevels.find(l => l.bloomLevel === i);
                    bloomLevelStates.push({
                        bloomLevel: i,
                        masteryScore: bm ? Math.round(bm.masteryScore) : 0,
                        achieved: bm ? bm.masteryScore >= BloomProgressService_1.BloomProgressService.MASTERY_THRESHOLD : false
                    });
                }
                return {
                    topicId: topic.id,
                    topicName: topic.name,
                    overallMastery: BloomProgressService_1.BloomProgressService.calculateWeightedMastery(bloomLevelStates),
                    bloomLevels: bloomLevelStates,
                    masteryBadge: BloomProgressService_1.BloomProgressService.calculateMasteryBadge(bloomLevelStates)
                };
            });
            const response = {
                courseId,
                userId,
                topics: topicProgressDtos
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error fetching course progress:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    };
}
exports.ProgressController = ProgressController;
