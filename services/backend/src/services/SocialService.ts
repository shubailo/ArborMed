import { prisma } from '../db';
import { RoomService } from './RoomService';

/**
 * SocialService handles read-only social interactions:
 * - Browsing other students' clinics (Clinic Directory).
 * - Visiting another student's clinic (Visiting Rooms).
 */
export class SocialService {
    /**
     * Get a paginated or limited list of students in the same course.
     * Returns their display name and coarse mastery band (estimated from BloomLevelProgress).
     */
    static async getClinicDirectory(courseId: string) {
        // Find users enrolled in the course via UserCourseProgress
        // Note: UserCourseProgress requires organizationId as well in its compound ID, 
        // but we can query just by courseId if we want all users in that course across orgs.
        // However, Prisma might require organizationId. Let's fetch the course first (if it's tied to an org) or just let findMany filter purely by courseId.
        const enrolledUsers = await prisma.userCourseProgress.findMany({
            where: { courseId },
            include: {
                user: {
                    select: {
                        id: true,
                        email: true,
                    }
                }
            },
            take: 50, // Limit to 50 for MVP
        });

        // We also need to map first/last name if it exists, but User model doesn't have firstName/lastName
        // Wait, looking at schema.prisma, User ONLY has email, role, masteryPoints, rewardBalance.
        // Let's use email to generate a display name for MVP (e.g. masking part of it).

        const entries = await Promise.all(enrolledUsers.map(async (enrollment) => {
            const userId = enrollment.user.id;

            // Calculate a simple coarse mastery band using UserBloomMastery.
            // Since we don't have courseId on UserBloomMastery, we'll get all masteries across the organization.
            const progress = await prisma.userBloomMastery.findMany({
                where: { userId }
            });

            // Calculate overall mastery
            let masteryBand: 'EARLY' | 'GROWING' | 'CONFIDENT' | 'ADVANCED' = 'EARLY';

            if (progress.length > 0) {
                const avgMastery = progress.reduce((acc, curr) => acc + curr.masteryScore, 0) / progress.length;

                if (avgMastery >= 90) {
                    masteryBand = 'ADVANCED';
                } else if (avgMastery >= 70) {
                    masteryBand = 'CONFIDENT';
                } else if (avgMastery >= 40) {
                    masteryBand = 'GROWING';
                }
            }

            // Create a display name from email (e.g. "student@email.com" -> "Student")
            const emailParts = (enrollment.user as any).email?.split('@') || ['Student'];
            let displayName = emailParts[0];
            // Capitalize first letter
            displayName = displayName.charAt(0).toUpperCase() + displayName.slice(1);

            return {
                userId,
                displayName,
                overallMasteryBand: masteryBand,
            };
        }));

        // Simple sorting by display name
        entries.sort((a, b) => a.displayName.localeCompare(b.displayName));

        return {
            courseId,
            entries
        };
    }

    /**
     * Get the read-only view of a student's room and profile.
     */
    static async getRoomVisit(visitorUserId: string, targetUserId: string, courseId: string) {
        // 1. Authorization check: Make sure visitor and target are in the same course
        const visitorEnrollment = await prisma.userCourseProgress.findFirst({
            where: { userId: visitorUserId, courseId }
        });

        const targetEnrollment = await prisma.userCourseProgress.findFirst({
            where: { userId: targetUserId, courseId },
            include: {
                user: {
                    select: {
                        email: true
                    }
                }
            }
        });

        if (!visitorEnrollment || !targetEnrollment) {
            const error = new Error('Cannot visit this room. Users must be enrolled in the same course.');
            (error as any).errorCode = 'UNAUTHORIZED_VISIT';
            throw error;
        }

        // 2. Fetch target user's basic info
        const emailParts = targetEnrollment.user.email?.split('@') || ['Student'];
        let displayName = emailParts[0];
        displayName = displayName.charAt(0).toUpperCase() + displayName.slice(1);

        // Calculate mastery band
        const progress = await prisma.userBloomMastery.findMany({
            where: { userId: targetUserId }
        });

        let masteryBand: 'EARLY' | 'GROWING' | 'CONFIDENT' | 'ADVANCED' = 'EARLY';

        if (progress.length > 0) {
            const avgMastery = progress.reduce((acc, curr) => acc + curr.masteryScore, 0) / progress.length;

            if (avgMastery >= 90) {
                masteryBand = 'ADVANCED';
            } else if (avgMastery >= 70) {
                masteryBand = 'CONFIDENT';
            } else if (avgMastery >= 40) {
                masteryBand = 'GROWING';
            }
        }

        // 3. Fetch target's room state
        const roomItems = await RoomService.getRoomState(targetUserId);

        // Map room state to DTO
        const formattedRoomItems = roomItems.map(item => ({
            id: item.id,
            slotKey: item.slotKey,
            shopItem: {
                id: item.shopItem.id,
                name: item.shopItem.name,
                assetUrl: (item.shopItem as any).assetUrl || null, // Handle potentially missing assetUrl in schema
                category: item.shopItem.category,
            }
        }));

        // Assemble Visit DTO
        return {
            userId: targetUserId,
            displayName,
            overallMasteryBand: masteryBand,
            roomLayout: {
                // Hardcoded layout id for MVP, or we would fetch if multiple exist
                id: 'clinical_cozy_01',
                theme: 'COZY',
            },
            roomItems: formattedRoomItems,
            bean: {
                // Simple heuristic for mood (e.g., happy if advancing, otherwise focused)
                mood: masteryBand === 'ADVANCED' ? 'happy' : 'focused'
            }
        };
    }
}
