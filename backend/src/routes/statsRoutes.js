const express = require('express');
const router = express.Router();
const { getSummary, getActivity, getSubjectDetail, getMistakesByTimeframe } = require('../controllers/statsController');
const { protect } = require('../middleware/authMiddleware');

/**
 * @route GET /api/stats/summary
 * @desc Get overall mastery for major subjects
 */
router.get('/summary', protect, getSummary);

/**
 * @route GET /api/stats/activity
 * @desc Get daily question activity
 */
router.get('/activity', protect, getActivity);

/**
 * @route GET /api/stats/mistakes
 * @desc Get question IDs missed by user in a timeframe
 */
router.get('/mistakes', protect, getMistakesByTimeframe);

/**
 * @route GET /api/stats/subject/:subjectSlug
 * @desc Get detailed mastery for a specific subject
 */
router.get('/subject/:subjectSlug', protect, getSubjectDetail);

/**
 * @route GET /api/stats/smart-review
 * @desc Get study recommendations
 */
router.get('/smart-review', protect, require('../controllers/statsController').getSmartReview);

/**
 * @route GET /api/stats/readiness
 * @desc Get exam readiness score
 */
router.get('/readiness', protect, require('../controllers/statsController').getReadiness);

/**
 * @route GET /api/stats/questions
 * @desc Get aggregate performance stats for all questions (Admin only)
 */
const { admin } = require('../middleware/adminMiddleware');
router.get('/questions', protect, admin, require('../controllers/statsController').getQuestionStats);
router.get('/admin/summary', protect, admin, require('../controllers/statsController').getAdminSummary);
router.get('/inventory-summary', protect, admin, require('../controllers/statsController').getInventorySummary);
router.get('/admin/users-performance', protect, admin, require('../controllers/statsController').getUsersPerformance);
router.get('/admin/users/:userId/history', protect, admin, require('../controllers/statsController').getUserHistory);
router.get('/admin/users/:userId/analytics', protect, admin, require('../controllers/statsController').getAdminUserAnalytics); // NEW

module.exports = router;
