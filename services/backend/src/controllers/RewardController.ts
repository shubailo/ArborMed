import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import * as rewardConfig from '../config/reward-config.json';

const prisma = new PrismaClient();

export class RewardController {

    static async getShopItems(req: Request, res: Response) {
        try {
            // In a real app, this might come from the DB, 
            // but for now, we use the config file as source of truth.
            res.json(rewardConfig.shopItems);
        } catch (error) {
            res.status(500).json({ error: 'Failed to fetch shop items' });
        }
    }

    static async purchaseItem(req: Request, res: Response) {
        const { userId, itemId } = req.body;

        try {
            const item = rewardConfig.shopItems.find(i => i.id === itemId);
            if (!item) return res.status(404).json({ error: 'Item not found' });

            const user = await prisma.user.findUnique({ where: { id: userId } });
            if (!user) return res.status(404).json({ error: 'User not found' });

            if (user.masteryPoints < item.price) {
                return res.status(400).json({ error: 'Insufficient points' });
            }

            // Transaction: Deduct points and add to inventory
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

            res.json({ success: true, remainingPoints: user.masteryPoints - item.price });
        } catch (error) {
            res.status(500).json({ error: 'Purchase failed' });
        }
    }

    static async getRoomLayout(req: Request, res: Response) {
        const { userId } = req.query;
        try {
            const layout = await prisma.userRoomItem.findMany({
                where: { userId: String(userId) },
                include: { shopItem: true }
            });
            res.json(layout);
        } catch (error) {
            res.status(500).json({ error: 'Failed to fetch layout' });
        }
    }

    static async updateRoomLayout(req: Request, res: Response) {
        const { userId, placements } = req.body; // placements: [{ itemId, slotIndex }]

        try {
            await prisma.$transaction([
                // Clear old layout
                prisma.userRoomItem.deleteMany({ where: { userId } }),
                // Add new layout
                prisma.userRoomItem.createMany({
                    data: placements.map((p: any) => ({
                        userId,
                        shopItemId: p.itemId,
                        slotIndex: p.slotIndex
                    }))
                })
            ]);
            res.json({ success: true });
        } catch (error) {
            res.status(500).json({ error: 'Failed to update layout' });
        }
    }
}
