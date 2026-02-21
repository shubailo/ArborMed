import { prisma } from '../db';

export interface ActivityTrendPoint {
    date: string;
    questionsAnswered: number;
    correctRate: number;
}

export interface ActivityTrendsDto {
    range: '7d' | '30d';
    points: ActivityTrendPoint[];
}


export interface DailyPrescriptionDto {
    date: string;
    targetQuestions: number;
    answeredToday: number;
    completionRate: number;
}

export class StudentAnalyticsService {
    /**
     * Retrieves aggregated activity trends for a student
     */
    static async getActivityTrends(userId: string, courseId: string, range: '7d' | '30d' = '7d'): Promise<ActivityTrendsDto> {
        const days = range === '7d' ? 7 : 30;
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - days + 1); // include today
        startDate.setHours(0, 0, 0, 0);

        const events = await prisma.studyEvent.findMany({
            where: {
                userId,
                organizationId: courseId, // Note: backend often uses orgId interchangeably with courseId depending on the context, here assuming courseId = orgId
                createdAt: { gte: startDate }
            },
            select: {
                createdAt: true,
                isCorrect: true
            },
            orderBy: {
                createdAt: 'asc'
            }
        });

        const pointsMap: Record<string, { total: number, correct: number }> = {};

        // Ensure all dates are present in the map
        for (let i = 0; i < days; i++) {
            const d = new Date(startDate);
            d.setDate(d.getDate() + i);
            const dateStr = d.toISOString().split('T')[0];
            pointsMap[dateStr] = { total: 0, correct: 0 };
        }

        events.forEach(e => {
            const dateStr = e.createdAt.toISOString().split('T')[0];
            if (pointsMap[dateStr]) {
                pointsMap[dateStr].total++;
                if (e.isCorrect) pointsMap[dateStr].correct++;
            }
        });

        const points: ActivityTrendPoint[] = Object.keys(pointsMap).sort().map(date => {
            const data = pointsMap[date];
            return {
                date,
                questionsAnswered: data.total,
                correctRate: data.total > 0 ? data.correct / data.total : 0
            };
        });

        return {
            range,
            points
        };
    }

    /**
     * Retrieves the daily prescription (goals) for a student, accurately applying the client's timezone offset.
     */
    static async getDailyPrescription(userId: string, courseId: string, timezoneOffsetMinutes: number = 0): Promise<DailyPrescriptionDto> {
        const targetQuestions = 40;

        // Calculate the local time by subtracting the offset (JS offset is UTC - Local)
        const now = new Date();
        const localTime = new Date(now.getTime() - timezoneOffsetMinutes * 60000);
        const localDateStr = localTime.toISOString().split('T')[0];

        // Determine the UTC boundaries of the client's local day
        const startOfLocalDay = new Date(localTime);
        startOfLocalDay.setUTCHours(0, 0, 0, 0);

        const endOfLocalDay = new Date(localTime);
        endOfLocalDay.setUTCHours(23, 59, 59, 999);

        const startUtc = new Date(startOfLocalDay.getTime() + timezoneOffsetMinutes * 60000);
        const endUtc = new Date(endOfLocalDay.getTime() + timezoneOffsetMinutes * 60000);

        const events = await prisma.studyEvent.findMany({
            where: {
                userId,
                organizationId: courseId,
                createdAt: { gte: startUtc, lte: endUtc }
            }
        });

        const answeredToday = events.length;
        let completionRate = answeredToday / targetQuestions;
        if (completionRate > 1.0) completionRate = 1.0;

        return {
            date: localDateStr,
            targetQuestions,
            answeredToday,
            completionRate
        };
    }
}
