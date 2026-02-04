const express = require('express');
const router = express.Router();
const multer = require('multer');
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });
const { startSession, getNextQuestion, submitAnswer } = require('../controllers/quizController');
const { protect } = require('../middleware/authMiddleware');

router.post('/start', protect, startSession);
router.get('/next', protect, getNextQuestion);
router.get('/topics', protect, require('../controllers/quizController').getTopics);
router.get('/question-types', protect, require('../controllers/quizController').getQuestionTypes);
router.post('/answer', protect, submitAnswer);
router.get('/quote', protect, require('../controllers/quizController').getCurrentQuote);

// --- ADMIN ROUTES ---
const { admin } = require('../middleware/adminMiddleware');

/**
 * @route GET /api/quiz/admin/questions
 * @desc Get all questions (paginated) for admin management
 */
router.get('/admin/questions', protect, admin, require('../controllers/quizController').adminGetQuestions);

router.post('/admin/questions', protect, admin, require('../controllers/quizController').adminCreateQuestion);

/**
 * @route POST /api/quiz/admin/questions/bulk
 * @desc Bulk action (move/delete) on questions
 */
router.post('/admin/questions/bulk', protect, admin, require('../controllers/quizController').adminBulkAction);

/**
 * @route POST /api/quiz/admin/questions/batch
 * @desc Batch upload questions via CSV
 */
router.post('/admin/questions/batch', protect, admin, upload.single('file'), require('../controllers/quizController').adminBatchUpload);

/**
 * @route GET /api/quiz/admin/analytics/wall-of-pain
 * @desc Get pedagogical insights (Top failed questions/topics)
 */
router.get('/admin/analytics/wall-of-pain', protect, admin, require('../controllers/quizController').getWallOfPain);

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

/**
 * @route POST /api/quiz/admin/topics
 * @desc Create a new topic/section
 */
router.post('/admin/topics', protect, admin, require('../controllers/quizController').createTopic);

router.put('/admin/topics/:id', protect, admin, require('../controllers/quizController').updateTopic);

/**
 * @route DELETE /api/quiz/admin/topics/:id
 * @desc Delete a topic/section
 */
router.delete('/admin/topics/:id', protect, admin, require('../controllers/quizController').deleteTopic);

// --- QUOTE ADMIN ROUTES ---
router.get('/admin/quotes', protect, admin, require('../controllers/quizController').adminGetQuotes);
router.post('/admin/quotes', protect, admin, require('../controllers/quizController').adminCreateQuote);
router.put('/admin/quotes/:id', protect, admin, require('../controllers/quizController').adminUpdateQuote);
router.delete('/admin/quotes/:id', protect, admin, require('../controllers/quizController').adminDeleteQuote);

// --- TRANSLATION API ---
router.post('/translate', protect, require('../controllers/quizController').translate);

module.exports = router;
