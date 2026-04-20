const express = require('express');
const router = express.Router();
const gamificationController = require('../controllers/gamificationController');
const { protect } = require('../middleware/authMiddleware');

/**
 * Clinical residency progression routes.
 * All routes are protected and require a valid student session.
 */

router.get('/status', protect, gamificationController.getStatus);
router.post('/sync-rounds', protect, gamificationController.syncRounds);

module.exports = router;
