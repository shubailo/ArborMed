"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const DebugController_1 = require("../controllers/DebugController");
const router = (0, express_1.Router)();
router.get('/engine-decisions', DebugController_1.DebugController.getEngineDecisions);
router.get('/study-sessions', DebugController_1.DebugController.getStudySessions);
exports.default = router;
