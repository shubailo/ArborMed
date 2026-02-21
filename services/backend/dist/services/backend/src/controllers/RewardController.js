"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RewardController = void 0;
const RewardService_1 = require("../services/RewardService");
const db_1 = require("../db");
class RewardController {
    async getBalance(req, res) {
        try {
            const user = req.user;
            const userId = req.params.userId || user.id;
            const balance = await RewardService_1.RewardService.getBalance(userId);
            res.json({ userId, balance });
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    async getShopItems(req, res) {
        try {
            const items = await db_1.prisma.shopItem.findMany({
                where: { isActive: true }
            });
            res.json(items);
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    async purchaseItem(req, res) {
        try {
            const user = req.user;
            const userId = user.id;
            const { shopItemId } = req.body;
            if (!shopItemId) {
                res.status(400).json({ error: 'shopItemId is required' });
                return;
            }
            const result = await RewardService_1.RewardService.purchaseItem(userId, shopItemId);
            if (!result.success) {
                if (result.errorCode === 'INSUFFICIENT_FUNDS') {
                    res.status(422).json(result);
                }
                else {
                    res.status(400).json(result);
                }
                return;
            }
            res.json(result);
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    async getInventory(req, res) {
        try {
            const user = req.user;
            const userId = user.id;
            const inventory = await RewardService_1.RewardService.getInventory(userId);
            res.json(inventory);
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
}
exports.RewardController = RewardController;
