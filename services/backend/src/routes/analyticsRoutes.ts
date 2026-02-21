import { Router } from 'express';
import { AnalyticsController } from '../controllers/AnalyticsController';

const router = Router();
const analyticsController = new AnalyticsController();

router.get('/course/:courseId/overview', analyticsController.getCourseOverview);
router.get('/user/:userId/overview', analyticsController.getUserOverview);

export default router;
