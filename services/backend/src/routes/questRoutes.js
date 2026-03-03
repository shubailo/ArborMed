const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const questController = require('../controllers/questController');

router.post('/claim', protect, questController.claimQuest);

module.exports = router;
