const ranks = ['unmatched', 'intern', 'resident', 'attending', 'chief'];
const utcDay = "(CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::date";
// DATE is a calendar day. Return UTC midnight to keep the existing API timestamp format.
const standingColumns = `rank, malpractice_strikes,
    last_rounds_date::timestamp AT TIME ZONE 'UTC' AS last_rounds_date,
    ${utcDay} - last_rounds_date AS days_since_rounds`;

class ResidencyService {
    async ensureDailyClinicalStatus(client, userId) {
        const { rows } = await client.query(
            `SELECT ${standingColumns} FROM users WHERE id = $1 FOR UPDATE`, [userId]
        );
        const standing = rows[0];
        const elapsed = standing.days_since_rounds;
        if (elapsed !== null && elapsed <= 1) return standing;

        // A new resident starts with a grace day. An existing resident accrues one strike
        // per missed day and can still finish today's rounds to earn a pardon.
        let strikes = standing.malpractice_strikes;
        let rank = standing.rank;
        if (elapsed !== null) {
            strikes += elapsed - 1;
            if (strikes >= 5) {
                const previousRank = ranks[ranks.indexOf(rank) - 1];
                rank = previousRank ?? rank;
                strikes = previousRank ? 3 : 5;
            }
        }
        const updated = await client.query(`UPDATE users
            SET malpractice_strikes = $1, rank = $2, last_rounds_date = ${utcDay} - 1
            WHERE id = $3 RETURNING ${standingColumns}`, [strikes, rank, userId]);
        return updated.rows[0];
    }

    async syncCompletedRounds(client, userId) {
        const standing = await this.ensureDailyClinicalStatus(client, userId);
        if (standing.days_since_rounds === 0) return standing;

        // Older responses may identify their owner only through the quiz session.
        const { rows } = await client.query(`SELECT count(*)::int AS correct_count
            FROM responses r LEFT JOIN quiz_sessions qs ON r.session_id = qs.id
            WHERE coalesce(r.user_id, qs.user_id) = $1 AND r.is_correct
            AND r.created_at >= (${utcDay}::timestamp AT TIME ZONE 'UTC')`, [userId]);
        if (rows[0].correct_count < 10) return standing;

        const updated = await client.query(`UPDATE users
            SET last_rounds_date = ${utcDay}, malpractice_strikes = greatest(malpractice_strikes - 1, 0)
            WHERE id = $1 RETURNING ${standingColumns}`, [userId]);
        return updated.rows[0];
    }
}

module.exports = new ResidencyService();
