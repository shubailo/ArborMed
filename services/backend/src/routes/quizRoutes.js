const express = require('express');
const router = express.Router();
const multer = require('multer');
const quizController = require('../controllers/quizController');
const adminQuestionController = require('../controllers/adminQuestionController');
const topicController = require('../controllers/topicController');
const quoteController = require('../controllers/quoteController');
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
router.get('/quote', protect, quoteController.getCurrentQuote);
router.get('/questions/:id', protect, quizController.getQuestionById);
router.post('/translate', protect, quizController.translate);

// --- ADMIN QUESTION ROUTES ---
router.get('/admin/questions', protect, admin, adminQuestionController.adminGetQuestions);
router.post('/admin/questions', protect, admin, adminQuestionController.adminCreateQuestion);
router.post('/admin/questions/bulk', protect, admin, adminQuestionController.adminBulkAction);
router.get('/admin/questions/template', protect, admin, adminQuestionController.adminDownloadTemplate);
router.post('/admin/questions/batch', protect, admin, upload.single('file'), adminQuestionController.adminBatchUpload);
router.get('/admin/analytics/wall-of-pain', protect, admin, adminQuestionController.getWallOfPain);
router.put('/admin/questions/:id', protect, admin, adminQuestionController.adminUpdateQuestion);
router.delete('/admin/questions/:id', protect, admin, adminQuestionController.adminDeleteQuestion);
router.get('/admin/questions/:id', protect, admin, quizController.getQuestionById);

// --- TOPIC ROUTES ---
router.post('/admin/topics', protect, admin, topicController.createTopic);
router.put('/admin/topics/:id', protect, admin, topicController.updateTopic);
router.delete('/admin/topics/:id', protect, admin, topicController.deleteTopic);

// --- QUOTE ADMIN ROUTES ---
router.get('/admin/quotes', protect, admin, quoteController.getAllQuotes);
router.post('/admin/quotes', protect, admin, quoteController.createQuote);
router.put('/admin/quotes/:id', protect, admin, quoteController.updateQuote);
router.delete('/admin/quotes/:id', protect, admin, quoteController.deleteQuote);

module.exports = router;
