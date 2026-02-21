import { Request, Response, NextFunction } from 'express';
import { RewardService } from '../services/RewardService';

export class RewardController {
    private service = new RewardService();

    async getShopItems(req: Request, res: Response): Promise<void> {
        const items = await this.service.getShopItems();
        res.json(items);
    }

    async purchaseItem(req: Request, res: Response): Promise<void> {
        const { userId, itemId } = req.body;
        const result = await this.service.purchaseItem(userId, itemId);
        res.json(result);
    }

    async getRoomLayout(req: Request, res: Response): Promise<void> {
        const userId = (req.query.userId as string) || (req as any).user.id;
        const layout = await this.service.getRoomLayout(userId);
        res.json(layout);
    }

    async updateRoomLayout(req: Request, res: Response): Promise<void> {
        const userId = req.body.userId || (req as any).user.id;
        const { placements } = req.body;
        await this.service.updateRoomLayout(userId, placements);
        res.json({ success: true });
    }
}
