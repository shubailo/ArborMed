const { translateText, translateQuestion } = require('../services/translationService');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');

function languages(body) {
    if (![body?.from, body?.to].every(value => typeof value === 'string' && value.trim())) {
        throw new AppError('Source and target languages are required.', 400);
    }
    const pair = [body.from.trim(), body.to.trim()];
    if (pair[1].toLowerCase() === 'auto') throw new AppError('A target language is required.', 400);
    try {
        if (pair[0] !== 'auto') Intl.getCanonicalLocales(pair[0]);
        Intl.getCanonicalLocales(pair[1]);
    } catch {
        throw new AppError('Invalid source or target language tag.', 400);
    }
    return pair;
}

exports.translateText = catchAsync(async (req, res) => {
    const [from, to] = languages(req.body);
    const { text } = req.body;
    if (typeof text !== 'string' || !text.trim()) throw new AppError('Source text is required.', 400);
    res.json({ translated: await translateText(text, from, to) });
});

exports.translateQuestion = catchAsync(async (req, res) => {
    const [from, to] = languages(req.body);
    res.json({ translatedQuestion: await translateQuestion(req.body.questionData, from, to) });
});
