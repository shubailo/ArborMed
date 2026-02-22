const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

exports.auditLog = async ({ userId, actionType, severity, metadata }) => {
    try {
        await db.query(
            'INSERT INTO audit_logs (user_id, action_type, severity, metadata) VALUES ($1, $2, $3, $4)',
            [userId, actionType, severity, metadata || {}]
        );
    } catch (error) {
        // Internal utility - don't throw to end-user but log silently
        console.error('[AUDIT_FAILED]', error.message);
    }
};

exports.getLogs = catchAsync(async (req, res, next) => {
    const { limit = 100, type, userId } = req.query;
    let query = 'SELECT l.*, u.email FROM audit_logs l LEFT JOIN users u ON l.user_id = u.id WHERE 1=1';
    const params = [];

    if (type) {
        params.push(type);
        query += ` AND action_type = $${params.length}`;
    }

    if (userId) {
        params.push(userId);
        query += ` AND l.user_id = $${params.length}`;
    }

    query += ` ORDER BY l.created_at DESC LIMIT $${params.length + 1}`;
    const result = await db.query(query, [...params, limit]);

    res.json(result.rows);
});
