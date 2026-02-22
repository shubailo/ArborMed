const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { protect } = require('../middleware/authMiddleware');
const { admin } = require('../middleware/adminMiddleware');

// Student: Submit report
router.post('/', protect, reportController.submitReport);

// Admin: Get reports for a question
router.get('/question/:id', protect, admin, reportController.getReportsByQuestion);

// Admin: Update status
router.patch('/:id', protect, admin, reportController.updateReportStatus);

module.exports = router;
