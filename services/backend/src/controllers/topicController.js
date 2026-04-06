const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

// ⚡ Bolt: Replace inline correlated subquery with pre-aggregated CTE for O(1) performance
// What: Swapped the N+1 correlated subquery in getTopics with a Left Join to a grouped CTE.
// Why: Correlated subqueries cause a full scan of the questions table for every topic, causing O(N*M) explosions. A CTE groups once and joins.
// Impact: Changes a O(N*M) N+1 query to a O(1) bulk fetch and join. Significant latency and database CPU reduction.
// Measurement: Measure via Postgres EXPLAIN ANALYZE or simple API load testing.
exports.getTopics = catchAsync(async (req, res) => {
    const query = `
        WITH topic_counts AS (
            SELECT topic_id, COUNT(*) as question_count
            FROM questions
            WHERE active = TRUE
            GROUP BY topic_id
        )
        SELECT t.*, 
               COALESCE(tc.question_count, 0) as question_count
        FROM topics t
        LEFT JOIN topic_counts tc ON t.id = tc.topic_id
        ORDER BY t.parent_id NULLS FIRST, t.id
    `;
    const result = await db.query(query);
    // Explicit conversion needed as COUNT returns string in node-postgres
    const parsedRows = result.rows.map(row => ({
        ...row,
        question_count: parseInt(row.question_count, 10)
    }));
    res.json(parsedRows);
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
