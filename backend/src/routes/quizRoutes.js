const express = require('express');
const router = express.Router();
const multer = require('multer');
const quizController = require('../controllers/quizController');
const { protect } = require('../middleware/authMiddleware');
const { admin } = require('../middleware/adminMiddleware');

// Multer config for file uploads
const storage = multer.memoryStorage();
const upload = multer({ storage });

// --- PUBLIC ROUTES ---
router.post('/start', protect, quizController.startSession);
router.get('/next', protect, quizController.getNextQuestion);
router.get('/topics', protect, quizController.getTopics);
router.get('/question-types', protect, quizController.getQuestionTypes);
router.post('/answer', protect, quizController.submitAnswer);
router.get('/quote', protect, quizController.getCurrentQuote);
router.get('/questions/:id', protect, quizController.getQuestionById);
router.post('/translate', protect, quizController.translate);

// --- ADMIN ROUTES ---
router.get('/admin/questions', protect, admin, quizController.adminGetQuestions);
router.post('/admin/questions', protect, admin, quizController.adminCreateQuestion);
router.post('/admin/questions/bulk', protect, admin, quizController.adminBulkAction);
router.get('/admin/questions/template', protect, admin, quizController.adminDownloadTemplate);
router.post('/admin/questions/batch', protect, admin, upload.single('file'), quizController.adminBatchUpload);
router.get('/admin/analytics/wall-of-pain', protect, admin, quizController.getWallOfPain);
router.put('/admin/questions/:id', protect, admin, quizController.adminUpdateQuestion);
router.delete('/admin/questions/:id', protect, admin, quizController.adminDeleteQuestion);

// --- TOPIC ROUTES ---
router.post('/admin/topics', protect, admin, quizController.createTopic);
router.put('/admin/topics/:id', protect, admin, quizController.updateTopic);
router.delete('/admin/topics/:id', protect, admin, quizController.deleteTopic);

// --- QUOTE ADMIN ROUTES ---
router.get('/admin/quotes', protect, admin, quizController.adminGetQuotes);
router.post('/admin/quotes', protect, admin, quizController.adminCreateQuote);
router.put('/admin/quotes/:id', protect, admin, quizController.adminUpdateQuote);
router.delete('/admin/quotes/:id', protect, admin, quizController.adminDeleteQuote);

module.exports = router;
