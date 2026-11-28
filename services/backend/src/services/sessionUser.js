const db = require('../config/db');

const verified = 'id = $1 AND is_email_verified IS NOT FALSE AND email_session_version::text IS NOT DISTINCT FROM $2';
const activityDue = "(last_activity_at IS NULL OR last_activity_at < statement_timestamp() - interval '1 minute')";

function activeSessionGrant(userParam, sessionParam) {
    return ` AND EXISTS (SELECT FROM refresh_tokens WHERE id = ${sessionParam} AND user_id = ${userParam}
        AND revoked = FALSE AND expires_at > statement_timestamp())`;
}

async function findSessionUser(claims) {
    const params = [claims.id, claims.emailVersion ?? null];
    const grant = claims.sessionId === undefined ? '' : activeSessionGrant('$1', '$3');
    if (grant) params.push(claims.sessionId);
    const { rows } = await db.query(
        `SELECT id, email, role, assigned_subject_id, coins, xp, level, ${activityDue} AS activity_due
         FROM users WHERE ${verified}${grant}`, params
    );
    if (!rows.length) return null;
    const { activity_due, ...user } = rows[0];
    if (activity_due) {
        try {
            // Concurrent requests can see the same old value. Only the first writes it.
            await db.query(`UPDATE users SET last_activity_at = statement_timestamp()
                WHERE id IN (SELECT id FROM users WHERE ${verified}${grant} AND ${activityDue}
                    FOR NO KEY UPDATE SKIP LOCKED)`, params);
        } catch (error) {
            const code = /^[A-Z0-9]{5}$/.test(error?.code) ? error.code : 'unclassified';
            console.warn('[Activity] Could not update last seen', code);
        }
    }
    return user;
}

module.exports = { findSessionUser, activeSessionGrant };
