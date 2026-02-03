const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

/**
 * @route GET /api/notifications/inbox
 */
router.get('/inbox', notificationController.getInbox);

/**
 * @route PUT /api/notifications/:id/read
 */
router.put('/:id/read', notificationController.markAsRead);

module.exports = router;
