const db = require('../config/db');
const AppError = require('../utils/AppError');
const { withTransaction } = require('../utils/dbHelpers');
const { isSuperAdmin } = require('../utils/adminPrivileges');

const denied = () => new AppError('This question or topic is outside your assigned subject.', 403);

async function questionScope(user, client = db, lock = false) {
    if (user?.role !== 'admin' || user.assigned_subject_id === undefined) throw denied();
    // A database NULL explicitly denotes an unrestricted content editor.
    if (isSuperAdmin(user) || user.assigned_subject_id === null) return { userId: user.id, topics: null };
    // Topic moves are rare. Hold the hierarchy stable while a scoped question mutation validates its destination.
    if (lock) await client.query('LOCK TABLE topics IN SHARE MODE');
    const result = await client.query(
        `WITH RECURSIVE subject(id) AS (
            SELECT id FROM topics WHERE id = $1
            UNION SELECT t.id FROM topics t JOIN subject s ON t.parent_id = s.id
        )
        SELECT id FROM topics WHERE id IN (SELECT id FROM subject) ORDER BY id`,
        [user.assigned_subject_id]
    );
    return { userId: user.id, topics: result.rows.map(t => t.id) };
}

function questionFilter(scope, params, alias = 'q') {
    if (scope.topics === null) return 'TRUE';
    params.push(scope.userId, scope.topics);
    return `(${alias}.created_by = $${params.length - 1} OR ${alias}.topic_id = ANY($${params.length}::int[]))`;
}

function checkTopics(scope, ids) {
    if (scope.topics !== null && ids.some(id => !scope.topics.includes(Number(id)))) throw denied();
}

async function withQuestionWrite(userId, { questionIds = [], topicIds = [], changeHierarchy = false }, write) {
    return withTransaction(async client => {
        const actor = await client.query('SELECT id, role, email, assigned_subject_id FROM users WHERE id = $1 FOR SHARE', [userId]);
        if (changeHierarchy) await client.query('LOCK TABLE topics IN SHARE ROW EXCLUSIVE MODE');
        const scope = await questionScope(actor.rows[0], client, true);
        checkTopics(scope, topicIds);
        const ids = [...new Set(questionIds.map(Number))];
        if (ids.some(id => !Number.isSafeInteger(id) || id <= 0 || id > 2147483647)) throw new AppError('Invalid question ID.', 400);
        if (ids.length) {
            const locked = await client.query(
                'SELECT id, topic_id, created_by FROM questions WHERE id = ANY($1::int[]) ORDER BY id FOR UPDATE', [ids]);
            if (locked.rowCount !== ids.length) throw new AppError('Question not found', 404);
            if (scope.topics !== null && locked.rows.some(q => q.created_by !== userId && !scope.topics.includes(q.topic_id))) {
                throw denied();
            }
        }
        return write(client, scope);
    });
}

async function readQuestion(user, id) {
    const scope = await questionScope(user);
    const params = [id];
    const result = await db.query('SELECT q.* FROM questions q WHERE q.id = $1 AND ' + questionFilter(scope, params), params);
    if (!result.rowCount) throw new AppError('Question not found', 404);
    return result.rows[0];
}

module.exports = { questionScope, questionFilter, checkTopics, withQuestionWrite, readQuestion };
