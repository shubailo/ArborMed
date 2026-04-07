const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

exports.getTopics = catchAsync(async (req, res) => {
    // ⚡ Bolt: Replaced inline correlated subquery with CTE pre-aggregation to prevent N+1 execution overhead
    const query = `
        WITH topic_question_counts AS (
            SELECT topic_id, COUNT(*)::int as question_count
            FROM questions
            WHERE active = TRUE
            GROUP BY topic_id
        )
        SELECT t.*, 
               COALESCE(tqc.question_count, 0) as question_count
        FROM topics t
        LEFT JOIN topic_question_counts tqc ON t.id = tqc.topic_id
        ORDER BY t.parent_id NULLS FIRST, t.id
    `;
    const result = await db.query(query);
    res.json(result.rows);
});

exports.createTopic = catchAsync(async (req, res, next) => {
    const { name_en, name_hu, slug, parent_id, description } = req.body;

    if (!name_en || !slug) {
        return next(new AppError('Name and Slug are required', 400));
    }

    const result = await db.query(
        'INSERT INTO topics (name_en, name_hu, slug, parent_id, description) VALUES ($1, $2, $3, $4, $5) RETURNING *',
        [name_en, name_hu, slug, parent_id, description]
    );
    res.status(201).json(result.rows[0]);
});

exports.updateTopic = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const { name_en, name_hu, slug, parent_id, description } = req.body;

    const result = await db.query(
        'UPDATE topics SET name_en = $1, name_hu = $2, slug = $3, parent_id = $4, description = $5 WHERE id = $6 RETURNING *',
        [name_en, name_hu, slug, parent_id, description, id]
    );

    if (result.rows.length === 0) {
        return next(new AppError('Topic not found', 404));
    }

    res.json(result.rows[0]);
});
exports.deleteTopic = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const result = await db.query('DELETE FROM topics WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) return next(new AppError('Topic not found', 404));
    res.json({ message: 'Topic deleted' });
});
