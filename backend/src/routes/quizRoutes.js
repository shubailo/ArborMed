const express = require('express');
const router = express.Router();
const { startSession, getNextQuestion, submitAnswer } = require('../controllers/quizController');
const { protect } = require('../middleware/authMiddleware');

router.post('/start', protect, startSession);
router.get('/next', protect, getNextQuestion);
router.post('/answer', protect, submitAnswer);

module.exports = router;
