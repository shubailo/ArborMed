import prisma from '../db';

export async function calculateReadinessScore(userId: string, organizationId: string): Promise<number> {
    const masteries = await prisma.userMastery.findMany({
        where: { userId, organizationId },
        include: { question: true }
    });

    if (masteries.length === 0) return 0;

    let totalWeight = 0;
    let weightedSum = 0;

    for (const m of masteries) {
        const weight = m.question.bloomLevel >= 3 ? 1.5 : 1.0;
        let normalizedScore = (m.easiness / 2.5) * 100;

        const courseId = await findCourseIdForTopic(m.question.topicId, organizationId);

        if (courseId) {
            const userProgress = await (prisma as any).userCourseProgress.findUnique({
                where: { userId_courseId: { userId, courseId } }
            });
            if (userProgress) {
                const userLevel = userProgress.currentBloomLevel;
                const questionLevel = m.question.bloomLevel;

                if (userLevel === 4) normalizedScore *= 1.15;
                if (userLevel === 3) normalizedScore *= 1.05;

                if (userLevel === 1 && questionLevel >= 3 && m.easiness <= 2.0) {
                    normalizedScore *= 0.8;
                }
            }
        }

        weightedSum += normalizedScore * weight;
        totalWeight += weight;
    }

    const score = weightedSum / totalWeight;
    return Math.min(Math.max(Math.round(score), 0), 100);
}

// In-memory caching for topics
let _topicToCourseMap: Record<string, string> | null = null;
import * as fs from 'fs';
import * as path from 'path';

async function findCourseIdForTopic(topicId: string, orgId: string): Promise<string | null> {
    if (!_topicToCourseMap) {
        _topicToCourseMap = {};
        try {
            const configPath = path.join(__dirname, '..', 'config', 'courses-and-topics.json');
            const coursesConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
            for (const course of coursesConfig) {
                for (const topic of course.topics) {
                    _topicToCourseMap[topic.id] = course.id;
                }
            }
        } catch (e) {
            console.error('Failed to load courses config', e);
        }
    }

    return _topicToCourseMap[topicId] || null;
}
