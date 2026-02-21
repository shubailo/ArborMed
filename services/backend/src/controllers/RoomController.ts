import { Request, Response } from 'express';
import { RoomService } from '../services/RoomService';

export class RoomController {
    async getRoomState(req: Request, res: Response): Promise<void> {
        try {
            const user = (req as any).user;
            const userId = user.id;
            const state = await RoomService.getRoomState(userId);
            res.json(state);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    async placeItem(req: Request, res: Response): Promise<void> {
        try {
            const user = (req as any).user;
            const userId = user.id;
            const { slotKey, shopItemId } = req.body;

            if (!slotKey || !shopItemId) {
                res.status(400).json({ error: 'slotKey and shopItemId are required' });
                return;
            }

            const result = await RoomService.placeItem(userId, slotKey, shopItemId);
            res.json(result);
        } catch (error: any) {
            if (error.errorCode === 'INVALID_ITEM_FOR_SLOT' || error.errorCode === 'NO_INVENTORY_FOR_ITEM') {
                res.status(422).json({
                    success: false,
                    error: error.message,
                    errorCode: error.errorCode
                });
            } else {
                res.status(500).json({ error: error.message });
            }
        }
    }

    async clearSlot(req: Request, res: Response): Promise<void> {
        try {
            const user = (req as any).user;
            const userId = user.id;
            const { slotKey } = req.body;

            if (!slotKey) {
                res.status(400).json({ error: 'slotKey is required' });
                return;
            }

            const result = await RoomService.clearSlot(userId, slotKey);
            res.json(result);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }
}
