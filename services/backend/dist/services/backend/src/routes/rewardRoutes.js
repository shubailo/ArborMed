"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const RewardController_1 = require("../controllers/RewardController");
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
const controller = new RewardController_1.RewardController();
// All reward routes require authentication
router.use(auth_1.requireAuth);
router.get('/balance/:userId?', (req, res) => controller.getBalance(req, res));
router.get('/shop', (req, res) => controller.getShopItems(req, res));
router.get('/inventory', (req, res) => controller.getInventory(req, res));
router.post('/purchase', (req, res) => controller.purchaseItem(req, res));
exports.default = router;
