const express = require('express');
const router = express.Router();
const { translateText, translateQuestion } = require('../services/translationService');
const { protect } = require('../middleware/authMiddleware');

/**
 * POST /api/translate
 * Translate a single text string
 * Body: { text: string, from: string, to: string }
 */
router.post('/translate', protect, async (req, res) => {
    try {
        const { text, from, to } = req.body;

        if (!text || !from || !to) {
            return res.status(400).json({
                error: 'Missing required fields: text, from, to'
            });
        }

        const translated = await translateText(text, from, to);

        if (translated === null) {
            return res.status(500).json({
                error: 'Translation failed'
            });
        }

        res.json({ translated });
    } catch (error) {
        console.error('Translation endpoint error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * POST /api/translate/question
 * Translate an entire question with all fields
 * Body: { questionData: { questionText, options[], explanation }, from: string, to: string }
 */
router.post('/translate/question', protect, async (req, res) => {
    try {
        const { questionData, from, to } = req.body;

        if (!questionData || !from || !to) {
            return res.status(400).json({
                error: 'Missing required fields: questionData, from, to'
            });
        }

        const translatedQuestion = await translateQuestion(questionData, from, to);

        res.json({ translatedQuestion });
    } catch (error) {
        console.error('Question translation endpoint error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
