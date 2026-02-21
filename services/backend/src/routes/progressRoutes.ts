import { Router } from 'express';
import { ProgressController } from '../controllers/ProgressController';

const router = Router();
const progressController = new ProgressController();

// GET /progress/user/:userId/course/:courseId
router.get('/user/:userId/course/:courseId', (req, res) => progressController.getUserCourseProgress(req, res));

export default router;
