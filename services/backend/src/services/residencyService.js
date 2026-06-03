class ResidencyService {
    /**
     * Ranks hierarchy for demotion/promotion.
     */
    static RANKS = ['unmatched', 'intern', 'resident', 'chief'];

    /**
     * Checks for missed shifts and updates malpractice strikes based on elapsed time.
     * This simulates the "Professional Accountability" aspect of the residency.
     * 
     * @param {Object} client Database client/transaction
     * @param {number} userId 
     * @returns {Object} Updated clinical standing
     */
    async ensureDailyClinicalStatus(client, userId) {
        const { rows } = await client.query(`
            SELECT rank, malpractice_strikes, last_rounds_date
            FROM users
            WHERE id = $1 FOR UPDATE
        `, [userId]);

        const user = rows[0];
        const now = new Date();
        const today = new Date(now.getFullYear(), now.month, now.getDate()); // UTC Midnight
        
        let lastRounds = user.last_rounds_date ? new Date(user.last_rounds_date) : null;
        
        if (!lastRounds) {
            // New user or never completed rounds: set to yesterday to avoid immediate strike
            const yesterday = new Date(today);
            yesterday.setDate(yesterday.getDate() - 1);
            
            await client.query(`
                UPDATE users SET last_rounds_date = $1 WHERE id = $2
            `, [yesterday, userId]);
            
            return { ...user, last_rounds_date: yesterday };
        }

        const daysDiff = Math.floor((today - lastRounds) / (1000 * 60 * 60 * 24));

        if (daysDiff > 1) {
            // User missed shifts. Apply strikes.
            // 1 strike for each day missed beyond the first gap day.
            let newStrikes = user.malpractice_strikes + (daysDiff - 1);
            let currentRank = user.rank;

            // Handle Demotion at 5 strikes
            if (newStrikes >= 5) {
                const rankIndex = ResidencyService.RANKS.indexOf(currentRank);
                if (rankIndex > 0) {
                    currentRank = ResidencyService.RANKS[rankIndex - 1];
                    newStrikes = 3; // Reset to 3 strikes (start of probation) at lower rank
                } else {
                    newStrikes = 5; // Cap at 5 if already at lowest rank
                }
            }

            const updateRes = await client.query(`
                UPDATE users
                SET malpractice_strikes = $1,
                    rank = $2,
                    last_rounds_date = $3
                WHERE id = $4
                RETURNING rank, malpractice_strikes, last_rounds_date
            `, [newStrikes, currentRank, new Date(today.getTime() - (1000*60*60*24)), userId]); // Set rounds to yesterday so they can still do today's
            
            return updateRes.rows[0];
        }

        return user;
    }

    /**
     * Verifies today's progress and updates professional standing.
     * Implements "Progressive Pardon": 1 strike removed for finishing today's shift.
     */
    async syncCompletedRounds(client, userId) {
        // First ensure current standing is accurate (apply missed shifts)
        let standing = await this.ensureDailyClinicalStatus(client, userId);

        const today = new Date().toISOString().split('T')[0];
        const lastRoundsStr = standing.last_rounds_date ? standing.last_rounds_date.toISOString().split('T')[0] : null;

        // If rounds already done today, skip
        if (lastRoundsStr === today) {
            return standing;
        }

        // Check correct answers count for today
        const { rows } = await client.query(`
            SELECT COUNT(r.id)::int as correct_count
            FROM responses r
            JOIN quiz_sessions qs ON r.session_id = qs.id
            WHERE qs.user_id = $1
            AND r.is_correct = true
            AND r.created_at >= CURRENT_DATE
        `, [userId]);

        const correctCount = rows[0].correct_count;

        if (correctCount >= 10) {
            // Rounds completed!
            let newStrikes = standing.malpractice_strikes;
            
            // Progressive Pardon: remove 1 strike if they have any
            if (newStrikes > 0) {
                newStrikes -= 1;
            }

            const updateRes = await client.query(`
                UPDATE users
                SET last_rounds_date = CURRENT_DATE,
                    malpractice_strikes = $1
                WHERE id = $2
                RETURNING rank, malpractice_strikes, last_rounds_date
            `, [newStrikes, userId]);

            return updateRes.rows[0];
        }

        return standing;
    }
}

module.exports = new ResidencyService();
