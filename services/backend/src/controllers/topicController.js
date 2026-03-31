const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

exports.getTopics = catchAsync(async (req, res) => {
    // ⚡ Bolt: Optimize N+1 question count query
    // What: Replaced inline correlated subquery with a CTE and LEFT JOIN
    // Why: Inline subqueries cause O(N) execution overhead. A CTE pre-aggregates the counts in O(1) time.
    // Impact: Significantly reduces database load and query execution time as the number of topics and questions grows.
    // Measurement: Database query analysis should show a single table scan for questions instead of N index scans.
    const query = `
        WITH qc AS (
            SELECT topic_id, COUNT(*)::int as question_count
            FROM questions
            WHERE active = TRUE
            GROUP BY topic_id
        )
        SELECT t.*, 
               COALESCE(qc.question_count, 0)::int as question_count
        FROM topics t
        LEFT JOIN qc ON qc.topic_id = t.id
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
