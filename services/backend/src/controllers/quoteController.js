const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

exports.getAllQuotes = catchAsync(async (req, res, next) => {
    const result = await db.query('SELECT * FROM quotes ORDER BY created_at DESC');
    res.json(result.rows);
});

exports.getCurrentQuote = catchAsync(async (req, res, next) => {
    // Return a random quote or a "Quote of the Day"
    const result = await db.query('SELECT * FROM quotes ORDER BY RANDOM() LIMIT 1');
    if (result.rows.length === 0) {
        return res.json({ text_en: "Stay focused, you're doing great!", author: "MedBuddy" });
    }
    res.json(result.rows[0]);
});

exports.createQuote = catchAsync(async (req, res, next) => {
    const { text_en, text_hu, author } = req.body;
    const result = await db.query(
        'INSERT INTO quotes (text_en, text_hu, author) VALUES ($1, $2, $3) RETURNING *',
        [text_en, text_hu, author]
    );
    res.status(201).json(result.rows[0]);
});

exports.updateQuote = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const { text_en, text_hu, author } = req.body;
    const result = await db.query(
        'UPDATE quotes SET text_en = $1, text_hu = $2, author = $3 WHERE id = $4 RETURNING *',
        [text_en, text_hu, author, id]
    );
    if (result.rows.length === 0) return next(new AppError('Quote not found', 404));
    res.json(result.rows[0]);
});

exports.deleteQuote = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const result = await db.query('DELETE FROM quotes WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) return next(new AppError('Quote not found', 404));
    res.json({ message: 'Quote deleted' });
});
