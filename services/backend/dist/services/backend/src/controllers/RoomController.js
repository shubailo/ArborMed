"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RoomController = void 0;
const RoomService_1 = require("../services/RoomService");
class RoomController {
    async getRoomState(req, res) {
        try {
            const user = req.user;
            const userId = user.id;
            const state = await RoomService_1.RoomService.getRoomState(userId);
            res.json(state);
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    async placeItem(req, res) {
        try {
            const user = req.user;
            const userId = user.id;
            const { slotKey, shopItemId } = req.body;
            if (!slotKey || !shopItemId) {
                res.status(400).json({ error: 'slotKey and shopItemId are required' });
                return;
            }
            const result = await RoomService_1.RoomService.placeItem(userId, slotKey, shopItemId);
            res.json(result);
        }
        catch (error) {
            if (error.errorCode === 'INVALID_ITEM_FOR_SLOT' || error.errorCode === 'NO_INVENTORY_FOR_ITEM') {
                res.status(422).json({
                    success: false,
                    error: error.message,
                    errorCode: error.errorCode
                });
            }
            else {
                res.status(500).json({ error: error.message });
            }
        }
    }
    async clearSlot(req, res) {
        try {
            const user = req.user;
            const userId = user.id;
            const { slotKey } = req.body;
            if (!slotKey) {
                res.status(400).json({ error: 'slotKey is required' });
                return;
            }
            const result = await RoomService_1.RoomService.clearSlot(userId, slotKey);
            res.json(result);
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
}
exports.RoomController = RoomController;
