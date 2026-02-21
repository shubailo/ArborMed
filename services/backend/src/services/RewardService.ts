import prisma from '../db';
import * as rewardConfig from '../config/reward-config.json';
import { ShopItem } from '../models/RewardModels';

export class RewardService {

    async getShopItems(): Promise<ShopItem[]> {
        return rewardConfig.shopItems as ShopItem[];
    }

    async purchaseItem(userId: string, itemId: string): Promise<{ success: boolean; remainingPoints: number }> {
        const item = (rewardConfig.shopItems as ShopItem[]).find(i => i.id === itemId);
        if (!item) throw new Error('Item not found');

        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (!user) throw new Error('User not found');

        if (user.masteryPoints < item.price) {
            throw new Error('Insufficient points');
        }

        const remainingPoints = user.masteryPoints - item.price;

        await prisma.$transaction([
            prisma.user.update({
                where: { id: userId },
                data: { masteryPoints: { decrement: item.price } }
            }),
            prisma.userInventory.upsert({
                where: { userId_shopItemId: { userId, shopItemId: itemId } },
                create: { userId, shopItemId: itemId, quantity: 1 },
                update: { quantity: { increment: 1 } }
            })
        ]);

        return { success: true, remainingPoints };
    }

    async getRoomLayout(userId: string): Promise<any[]> {
        return await (prisma.userRoomItem as any).findMany({
            where: { userId: String(userId) },
            include: { shopItem: true }
        });
    }

    async updateRoomLayout(userId: string, placements: any[]): Promise<void> {
        await prisma.$transaction([
            prisma.userRoomItem.deleteMany({ where: { userId: String(userId) } }),
            prisma.userRoomItem.createMany({
                data: placements.map((p: any) => ({
                    userId: String(userId),
                    shopItemId: String(p.itemId),
                    slotIndex: Number(p.slotIndex) || 0,
                    posX: 0,
                    posY: 0,
                    rotation: 0
                }))
            })
        ]);
    }
}
