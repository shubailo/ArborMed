import { Router } from 'express';
import { AnalyticsController } from '../controllers/AnalyticsController';

const router = Router();
const analyticsController = new AnalyticsController();

router.get('/course/:courseId/overview', analyticsController.getCourseOverview);
router.get('/course/:courseId/mastery-over-time', analyticsController.getMasteryOverTime);
router.get('/course/:courseId/topic-bloom-breakdown', analyticsController.getTopicBloomBreakdown);
router.get('/course/:courseId/engagement', analyticsController.getEngagement);
router.get('/course/:courseId/retention-over-time', analyticsController.getRetentionOverTime);
router.get('/course/:courseId/bloom-usage-summary', analyticsController.getBloomUsageSummary);
router.get('/user/:userId/overview', analyticsController.getUserOverview);
router.get('/user/:userId/course/:courseId/activity-trends', analyticsController.getActivityTrends);
router.get('/user/:userId/course/:courseId/daily-prescription', analyticsController.getDailyPrescription);

export default router;
