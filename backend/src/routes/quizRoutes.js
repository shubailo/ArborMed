const express = require('express');
const router = express.Router();
const { startSession, getNextQuestion, submitAnswer } = require('../controllers/quizController');
const { protect } = require('../middleware/authMiddleware');

router.post('/start', protect, startSession);
router.get('/next', protect, getNextQuestion);
router.get('/topics', protect, require('../controllers/quizController').getTopics);
router.post('/answer', protect, submitAnswer);

// --- ADMIN ROUTES ---
const { admin } = require('../middleware/adminMiddleware');

/**
 * @route GET /api/quiz/admin/questions
 * @desc Get all questions (paginated) for admin management
 */
router.get('/admin/questions', protect, admin, require('../controllers/quizController').adminGetQuestions);

/**
 * @route POST /api/quiz/admin/questions
 * @desc Create a new question
 */
router.post('/admin/questions', protect, admin, require('../controllers/quizController').adminCreateQuestion);

/**
 * @route PUT /api/quiz/admin/questions/:id
 * @desc Update an existing question
 */
router.put('/admin/questions/:id', protect, admin, require('../controllers/quizController').adminUpdateQuestion);

/**
 * @route DELETE /api/quiz/admin/questions/:id
 * @desc Delete a question
 */
router.delete('/admin/questions/:id', protect, admin, require('../controllers/quizController').adminDeleteQuestion);

module.exports = router;
