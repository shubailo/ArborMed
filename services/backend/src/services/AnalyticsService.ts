import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function calculateReadinessScore(userId: string, organizationId: string): Promise<number> {
    const masteries = await prisma.userMastery.findMany({
        where: { userId, organizationId },
        include: { question: true }
    });

    if (masteries.length === 0) return 0;

    // Logic: Weighted average of easiness factors
    // penalty for high bloom steps? Or bonus for high bloom mastery?
    // Let's use: (avgEasiness / 2.5) * 100, capped at 100.
    // And weight Bloom 3/4 more heavily.

    let totalWeight = 0;
    let weightedSum = 0;

    for (const m of masteries) {
        const weight = m.question.bloomLevel >= 3 ? 1.5 : 1.0;
        // Easiness is usually 1.3 to 2.5+. We normalize 2.5 to 100%
        const normalizedScore = (m.easiness / 2.5) * 100;

        weightedSum += normalizedScore * weight;
        totalWeight += weight;
    }

    const score = weightedSum / totalWeight;
    return Math.min(Math.max(Math.round(score), 0), 100);
}
