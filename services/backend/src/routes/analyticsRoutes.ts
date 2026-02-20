import { Router } from 'express';
import { AnalyticsController } from '../controllers/AnalyticsController';

const router = Router();

router.get('/course/:courseId/overview', AnalyticsController.getCourseOverview);
router.get('/user/:userId/overview', AnalyticsController.getUserOverview);

export default router;
