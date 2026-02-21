"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const ProgressController_1 = require("../controllers/ProgressController");
const router = (0, express_1.Router)();
const progressController = new ProgressController_1.ProgressController();
// GET /progress/user/:userId/course/:courseId
router.get('/user/:userId/course/:courseId', (req, res) => progressController.getUserCourseProgress(req, res));
exports.default = router;
