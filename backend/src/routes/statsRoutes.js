const express = require('express');
const router = express.Router();
const { getSummary, getActivity, getSubjectDetail } = require('../controllers/statsController');
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
 * @route GET /api/stats/subject/:subjectSlug
 * @desc Get detailed mastery for a specific subject
 */
router.get('/subject/:subjectSlug', protect, getSubjectDetail);

module.exports = router;
