const db = require('../config/db');
const { withQuestionWrite, checkTopics } = require('../services/adminQuestionAccess');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

exports.getTopics = catchAsync(async (req, res) => {
    const query = `
        SELECT t.*, 
               (SELECT COUNT(*) FROM questions q WHERE q.topic_id = t.id AND q.active = TRUE) as question_count
        FROM topics t
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

    const result = await withQuestionWrite(req.user.id, { topicIds: [parent_id], changeHierarchy: true }, client => client.query(
        'INSERT INTO topics (name_en, name_hu, slug, parent_id, description) VALUES ($1, $2, $3, $4, $5) RETURNING *',
        [name_en, name_hu, slug, parent_id, description]
    ));
    res.status(201).json(result.rows[0]);
});

exports.updateTopic = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const { name_en, name_hu, slug, parent_id, description } = req.body;

    const result = await withQuestionWrite(req.user.id, { topicIds: [id], changeHierarchy: true }, async (client, scope) => {
        const current = await client.query('SELECT parent_id FROM topics WHERE id = $1', [id]);
        if (!current.rowCount) throw new AppError('Topic not found', 404);
        const parent = parent_id == null ? null : Number(parent_id);
        if (parent !== current.rows[0].parent_id) {
            checkTopics(scope, [parent]);
            const cycle = await client.query(
                `WITH RECURSIVE subtree(id) AS (SELECT id FROM topics WHERE id = $1
                 UNION SELECT t.id FROM topics t JOIN subtree s ON t.parent_id = s.id)
                 SELECT FROM subtree WHERE id = $2`, [id, parent]);
            if (cycle.rowCount) throw new AppError('A topic cannot be moved under itself or a descendant.', 400);
        }
        return client.query(
            'UPDATE topics SET name_en = $1, name_hu = $2, slug = $3, parent_id = $4, description = $5 WHERE id = $6 RETURNING *',
            [name_en, name_hu, slug, parent, description, id]);
    });

    if (result.rows.length === 0) {
        return next(new AppError('Topic not found', 404));
    }

    res.json(result.rows[0]);
});
exports.deleteTopic = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const result = await withQuestionWrite(req.user.id, { topicIds: [id], changeHierarchy: true },
        client => client.query('DELETE FROM topics WHERE id = $1 RETURNING *', [id]));
    if (result.rows.length === 0) return next(new AppError('Topic not found', 404));
    res.json({ message: 'Topic deleted' });
});
