const express = require('express');
const router = express.Router();
const translation = require('../controllers/translationController');
const { protect } = require('../middleware/authMiddleware');

router.post('/translate', protect, translation.translateText);
router.post('/translate/question', protect, translation.translateQuestion);

module.exports = router;
