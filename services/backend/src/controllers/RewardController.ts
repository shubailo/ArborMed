import { Request, Response } from 'express';
import { RewardService } from '../services/RewardService';
import { prisma } from '../db';

export class RewardController {
    async getBalance(req: Request, res: Response): Promise<void> {
        try {
            const user = (req as any).user;
            const userId = req.params.userId || user.id;
            const balance = await RewardService.getBalance(userId);
            res.json({ userId, balance });
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    async getShopItems(req: Request, res: Response): Promise<void> {
        try {
            const items = await prisma.shopItem.findMany({
                where: { isActive: true }
            });
            res.json(items);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    async purchaseItem(req: Request, res: Response): Promise<void> {
        try {
            const user = (req as any).user;
            const userId = user.id;
            const { shopItemId } = req.body;

            if (!shopItemId) {
                res.status(400).json({ error: 'shopItemId is required' });
                return;
            }

            const result = await RewardService.purchaseItem(userId, shopItemId);
            if (!result.success) {
                if (result.errorCode === 'INSUFFICIENT_FUNDS') {
                    res.status(422).json(result);
                } else {
                    res.status(400).json(result);
                }
                return;
            }

            res.json(result);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    async getInventory(req: Request, res: Response): Promise<void> {
        try {
            const user = (req as any).user;
            const userId = user.id;
            const inventory = await RewardService.getInventory(userId);
            res.json(inventory);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }
}
