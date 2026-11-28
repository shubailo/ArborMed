const AppError = require('../utils/AppError');
const roundsGoal = 10;
const ranks = ['unmatched', 'intern', 'resident', 'attending', 'chief'];
const utcDay = "(statement_timestamp() AT TIME ZONE 'UTC')::date";
// DATE is a calendar day. Return UTC midnight to keep the existing API timestamp format.
const standingColumns = day => `COALESCE(rank, 'unmatched') AS rank, COALESCE(malpractice_strikes, 0) AS malpractice_strikes,
    ${day}::date::text AS study_day,
    last_rounds_date::timestamp AT TIME ZONE 'UTC' AS last_rounds_date,
    ${day}::date - last_rounds_date AS days_since_rounds`;

class ResidencyService {
    async ensureDailyClinicalStatus(client, userId, studyDay) {
        const locked = await client.query('SELECT id FROM users WHERE id = $1 FOR UPDATE', [userId]);
        if (!locked.rowCount) throw new AppError('User not found', 404);
        // Anchor the study day after acquiring the lock, then keep that day for every write.
        const { rows } = await client.query(
            `SELECT ${standingColumns(utcDay)}, statement_timestamp()::text AS study_time
             FROM users WHERE id = $1`, [userId]
        );
        const standing = rows[0];
        if (studyDay !== undefined && studyDay !== standing.study_day) {
            throw new AppError('The UTC study day has changed', 409);
        }
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
            SET malpractice_strikes = $1, rank = $2, last_rounds_date = $4::date - 1
            WHERE id = $3 RETURNING ${standingColumns('$4')}`, [strikes, rank, userId, standing.study_day]);
        return {...updated.rows[0], study_time: standing.study_time};
    }

    async dailyStatus(client, userId, { complete = false, studyDay } = {}) {
        let standing = await this.ensureDailyClinicalStatus(client, userId, studyDay);
        // Only the progress towards the daily goal is needed. A legacy row
        // without an explicit owner belongs to the owner of its session.
        const { rows } = await client.query(`SELECT count(*)::int AS progress FROM (
            SELECT 1 FROM responses r
            WHERE r.is_correct
              AND r.created_at >= ($2::date::timestamp AT TIME ZONE 'UTC')
              AND r.created_at <= $4::timestamptz
              AND (r.user_id = $1 OR (r.user_id IS NULL AND EXISTS (
                    SELECT 1 FROM quiz_sessions qs WHERE qs.id = r.session_id AND qs.user_id = $1)))
            LIMIT $3
        ) AS qualifying`, [userId, standing.study_day, roundsGoal, standing.study_time]);
        const progress = rows[0].progress;
        if (complete && standing.days_since_rounds > 0 && progress === roundsGoal) {
            const updated = await client.query(`UPDATE users SET last_rounds_date = $2::date,
                malpractice_strikes = greatest(coalesce(malpractice_strikes, 0) - 1, 0)
                WHERE id = $1 RETURNING ${standingColumns('$2')}`, [userId, standing.study_day]);
            standing = updated.rows[0];
        }
        return {
            rank: standing.rank, malpracticeStrikes: standing.malpractice_strikes,
            lastRoundsDate: standing.last_rounds_date, isOnProbation: standing.malpractice_strikes >= 3,
            studyDay: standing.study_day, roundsGoal, roundsProgress: progress,
            roundsCompleted: standing.days_since_rounds === 0
        };
    }
}

module.exports = new ResidencyService();
