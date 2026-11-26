const db = require('../config/db');

const verified = 'id = $1 AND is_email_verified IS NOT FALSE AND email_session_version::text IS NOT DISTINCT FROM $2';
const activityDue = "(last_activity_at IS NULL OR last_activity_at < statement_timestamp() - interval '1 minute')";

async function findSessionUser(claims) {
    const params = [claims.id, claims.emailVersion ?? null];
    const { rows } = await db.query(
        `SELECT id, email, role, assigned_subject_id, coins, xp, level, ${activityDue} AS activity_due
         FROM users WHERE ${verified}`, params
    );
    if (!rows.length) return null;
    const { activity_due, ...user } = rows[0];
    if (activity_due) {
        try {
            // Concurrent requests can see the same old value. Only the first writes it.
            await db.query(`UPDATE users SET last_activity_at = statement_timestamp()
                WHERE id IN (SELECT id FROM users WHERE ${verified} AND ${activityDue}
                    FOR NO KEY UPDATE SKIP LOCKED)`, params);
        } catch (error) {
            const code = /^[A-Z0-9]{5}$/.test(error?.code) ? error.code : 'unclassified';
            console.warn('[Activity] Could not update last seen', code);
        }
    }
    return user;
}

module.exports = { findSessionUser };
