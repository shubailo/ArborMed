const { createHash } = require('node:crypto');
const { withTransaction } = require('../utils/dbHelpers');
const AppError = require('../utils/AppError');

async function deliverBroadcast(actorId, body = {}) {
    const title = typeof body.title === 'string' ? body.title.trim() : '';
    const message = typeof body.message === 'string' ? body.message.trim() : '';
    const requestId = typeof body.requestId === 'string' ? body.requestId.toLowerCase() : '';
    if (!title || title.length > 120 || !message || message.length > 4000) {
        throw new AppError('A title up to 120 and a message up to 4000 characters are required.', 400);
    }
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(requestId)) {
        throw new AppError('A valid broadcast request ID is required.', 400);
    }
    const digest = createHash('sha256').update(JSON.stringify([title, message])).digest('hex');
    return withTransaction(async client => {
        // Serializing per sender makes concurrent retries see the committed receipt.
        const actor = await client.query("SELECT id FROM users WHERE id=$1 AND role='admin' FOR UPDATE", [actorId]);
        if (!actor.rowCount) throw new AppError('Administrator access required.', 403);
        const { rows: [receipt] } = await client.query(`
            SELECT details FROM admin_audit_log WHERE admin_id=$1 AND action='broadcast'
              AND details->>'request_id'=$2`, [actorId, requestId]);
        if (receipt) {
            if (receipt.details.digest !== digest) throw new AppError('This broadcast ID belongs to a different message.', 409);
            return { delivered: receipt.details.delivered, replayed: true };
        }
        const { rowCount: delivered } = await client.query(`
            INSERT INTO notifications (user_id, sender_id, message, type)
            SELECT id, $1, $2, 'admin_alert' FROM users
            WHERE role = 'student' AND email NOT IN ('test_reset@example.com', 'hemmy@arbormed.ai', 'endre@medbuddy.ai')`,
        [actorId, title + '\n\n' + message]);
        await client.query("INSERT INTO admin_audit_log (admin_id, action, details) VALUES ($1, 'broadcast', $2)",
            [actorId, { request_id: requestId, digest, delivered }]);
        return { delivered, replayed: false };
    });
}

module.exports = { deliverBroadcast };
