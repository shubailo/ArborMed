"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const RoomController_1 = require("../controllers/RoomController");
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
const controller = new RoomController_1.RoomController();
// All room routes require authentication
router.use(auth_1.requireAuth);
router.get('/', (req, res) => controller.getRoomState(req, res));
router.post('/place', (req, res) => controller.placeItem(req, res));
router.post('/clear', (req, res) => controller.clearSlot(req, res));
exports.default = router;
