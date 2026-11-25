const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');
const storage = require('../services/uploadStorage');

function quoteFields(body = {}) {
    if (typeof body.text_en !== 'string' || !body.text_en.trim()) {
        throw new AppError('English quote text is required', 400);
    }
    for (const [field, limit] of Object.entries({ text_hu: Infinity, author: 255,
        title_en: 100, title_hu: 100, icon_name: 50, custom_icon_url: Infinity })) {
        const value = body[field];
        if (value != null && (typeof value !== 'string' || (value.length > limit && Array.from(value).length > limit))) {
            throw new AppError('Invalid quote field: ' + field, 400);
        }
    }
    return [body.text_en.trim(), body.text_hu, body.author, body.title_en,
        body.title_hu, body.icon_name, body.custom_icon_url];
}

exports.getAllQuotes = catchAsync(async (req, res) => {
    const result = await db.query('SELECT * FROM quotes ORDER BY created_at DESC');
    res.json(result.rows);
});

exports.getCurrentQuote = catchAsync(async (req, res) => {
    // Return a random quote or a "Quote of the Day"
    const result = await db.query('SELECT * FROM quotes ORDER BY RANDOM() LIMIT 1');
    if (result.rows.length === 0) {
        return res.json({ text_en: "Stay focused, you're doing great!", author: "MedBuddy" });
    }
    const quote = result.rows[0];
    if (quote.custom_icon_url === 'random_gallery' || quote.icon_name === 'random_gallery') {
        let icon = null;
        try {
            icon = await storage.randomIcon();
        } catch (error) {
            console.warn('[Quote] Could not select a gallery icon:', error.message);
        }
        return res.json({ ...quote, icon_name: icon ? 'custom' : 'menu_book_rounded', custom_icon_url: icon });
    }
    res.json(quote);
});

exports.createQuote = catchAsync(async (req, res) => {
    const result = await db.query(
        `INSERT INTO quotes (text_en, text_hu, author, title_en, title_hu, icon_name, custom_icon_url)
         VALUES ($1, COALESCE($2, ''), COALESCE($3, ''), COALESCE($4, 'Study Break'),
                 COALESCE($5, 'Tanulás'), COALESCE($6, 'menu_book_rounded'), $7) RETURNING *`,
        quoteFields(req.body)
    );
    res.status(201).json(result.rows[0]);
});

exports.updateQuote = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const result = await db.query(
        `UPDATE quotes SET text_en = $1, text_hu = COALESCE($2, text_hu), author = COALESCE($3, author),
             title_en = COALESCE($4, title_en), title_hu = COALESCE($5, title_hu),
             icon_name = COALESCE($6, icon_name),
             custom_icon_url = CASE WHEN $8 THEN $7 ELSE custom_icon_url END
         WHERE id = $9 RETURNING *`,
        [...quoteFields(req.body), Object.hasOwn(req.body, 'custom_icon_url'), id]
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
