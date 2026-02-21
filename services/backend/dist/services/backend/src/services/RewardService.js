"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RewardService = void 0;
const db_1 = require("../db");
class RewardService {
    /**
     * Map quality (0-5) to reward points
     * quality 0-1 -> 0 points
     * quality 2-3 -> 1 point
     * quality 4   -> 2 points
     * quality 5   -> 3 points
     */
    static mapQualityToRewardPoints(quality) {
        if (quality <= 1)
            return 0;
        if (quality <= 3)
            return 1;
        if (quality === 4)
            return 2;
        if (quality === 5)
            return 3;
        return 0;
    }
    /**
     * Update user balance based on study result quality
     */
    static async addRewardPoints(userId, quality) {
        const points = this.mapQualityToRewardPoints(quality);
        if (points === 0) {
            const user = await db_1.prisma.user.findUnique({
                where: { id: userId },
                select: { rewardBalance: true }
            });
            return user?.rewardBalance ?? 0;
        }
        const updatedUser = await db_1.prisma.user.update({
            where: { id: userId },
            data: {
                rewardBalance: {
                    increment: points
                }
            },
            select: { rewardBalance: true }
        });
        return updatedUser.rewardBalance;
    }
    /**
     * Get current reward balance for a user
     */
    static async getBalance(userId) {
        const user = await db_1.prisma.user.findUnique({
            where: { id: userId },
            select: { rewardBalance: true }
        });
        return user?.rewardBalance ?? 0;
    }
    /**
     * Process a purchase
     */
    static async purchaseItem(userId, shopItemId) {
        return await db_1.prisma.$transaction(async (tx) => {
            const user = await tx.user.findUnique({
                where: { id: userId },
                select: { rewardBalance: true }
            });
            if (!user)
                throw new Error('User not found');
            const item = await tx.shopItem.findUnique({
                where: { id: shopItemId }
            });
            if (!item)
                throw new Error('Item not found');
            if (!item.isActive)
                throw new Error('Item is not available');
            if (user.rewardBalance < item.price) {
                return {
                    success: false,
                    error: 'Not enough Stethoscope points to buy this item.',
                    errorCode: 'INSUFFICIENT_FUNDS',
                    balance: user.rewardBalance
                };
            }
            // Deduct balance
            const updatedUser = await tx.user.update({
                where: { id: userId },
                data: {
                    rewardBalance: {
                        decrement: item.price
                    }
                },
                select: { rewardBalance: true }
            });
            // Add to inventory
            await tx.userInventory.upsert({
                where: {
                    userId_shopItemId: { userId, shopItemId }
                },
                update: {
                    quantity: { increment: 1 }
                },
                create: {
                    userId,
                    shopItemId,
                    quantity: 1
                }
            });
            // Create purchase record
            await tx.purchase.create({
                data: {
                    userId,
                    shopItemId,
                    pricePaid: item.price
                }
            });
            return { success: true, balance: updatedUser.rewardBalance };
        });
    }
    /**
     * Get user inventory
     */
    static async getInventory(userId) {
        return await db_1.prisma.userInventory.findMany({
            where: { userId },
            include: {
                shopItem: true
            }
        });
    }
}
exports.RewardService = RewardService;
