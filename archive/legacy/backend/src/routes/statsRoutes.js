const express = require('express');
const router = express.Router();
const statsController = require('../controllers/statsController');
const { protect } = require('../middleware/authMiddleware');
const { admin } = require('../middleware/adminMiddleware');

// --- USER ROUTES ---
router.get('/summary', protect, statsController.getSummary);
router.get('/activity', protect, statsController.getActivity);
router.get('/mistakes', protect, statsController.getMistakesByTimeframe);
router.get('/subject/:subjectSlug', protect, statsController.getSubjectDetail);
router.get('/smart-review', protect, statsController.getSmartReview);
router.get('/readiness', protect, statsController.getReadiness);

// --- ADMIN ROUTES ---
router.get('/questions', protect, admin, statsController.getQuestionStats);
router.get('/admin/summary', protect, admin, statsController.getAdminSummary);
router.get('/inventory-summary', protect, admin, statsController.getInventorySummary);
router.get('/admin/users-performance', protect, admin, statsController.getUsersPerformance);
router.get('/admin/users/:userId/history', protect, admin, statsController.getUserHistory);
router.get('/admin/users/:userId/analytics', protect, admin, statsController.getAdminUserAnalytics);

module.exports = router;
