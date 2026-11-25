const express = require('express');
const router = express.Router();
const { translateText, translateQuestion } = require('../services/translationService');
const { protect } = require('../middleware/authMiddleware');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');

function languages(body) {
    if (![body?.from, body?.to].every(value => typeof value === 'string' && value.trim())) {
        throw new AppError('Source and target languages are required.', 400);
    }
    return [body.from.trim(), body.to.trim()];
}

router.post('/translate', protect, catchAsync(async (req, res) => {
    const [from, to] = languages(req.body);
    const { text } = req.body;
    if (typeof text !== 'string' || !text.trim()) throw new AppError('Source text is required.', 400);
    res.json({ translated: await translateText(text, from, to) });
}));

router.post('/translate/question', protect, catchAsync(async (req, res) => {
    const [from, to] = languages(req.body);
    res.json({ translatedQuestion: await translateQuestion(req.body.questionData, from, to) });
}));

module.exports = router;
