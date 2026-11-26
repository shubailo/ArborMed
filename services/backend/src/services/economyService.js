const AppError = require('../utils/AppError');
const dailyQuests = [
    { id: 'daily_1', type: 'questionsAnswered', title: 'Daily Practice', titleHu: 'Napi gyakorlás',
        description: 'Complete 10 different questions today', descriptionHu: 'Válaszolj ma 10 különböző kérdésre.', targetCount: 10, rewardTokens: 10 },
    { id: 'daily_2', type: 'correctAnswers', title: 'Accuracy Master', titleHu: 'Pontos válaszok',
        description: 'Answer 5 different questions correctly today', descriptionHu: 'Válaszolj ma helyesen 5 különböző kérdésre.', targetCount: 5, rewardTokens: 20 },
    { id: 'daily_3', type: 'perfectScore', title: 'Perfectionist', titleHu: 'Hibátlan kezdés',
        description: 'Answer the first 5 questions in a session correctly. Each question must be different.', descriptionHu: 'Egy kvízben az első 5 különböző kérdésre adj helyes választ.', targetCount: 5, rewardTokens: 30 }
];

class EconomyService {
    /**
     * Resets the user's daily coin tracking if the last reset date is not today.
     * Must be called within a transaction context to prevent race conditions.
     * @param {Object} client Database client
     * @param {number} userId
     * @param {string} rewardDay UTC date returned by the locked reward ledger write
     * @returns {Object} User's current economy state
     */
    async ensureDailyReset(client, userId, rewardDay) {
        const { rows } = await client.query(`
            SELECT daily_coins_earned, daily_coins_softcap_progress, day::text AS reward_day,
                   last_coin_reset_date = day AS reset_today
            FROM users CROSS JOIN (
                SELECT COALESCE($2::date, (statement_timestamp() AT TIME ZONE 'UTC')::date) AS day
            ) AS clock
            WHERE id = $1 FOR UPDATE OF users
        `, [userId, rewardDay]);

        let userState = rows[0];
        if (!userState) throw new AppError('User not found', 404);

        if (!userState.reset_today) {
            const updateRes = await client.query(`
                UPDATE users
                SET daily_coins_earned = 0,
                    daily_coins_softcap_progress = 0,
                    last_coin_reset_date = $2::date
                WHERE id = $1
                RETURNING daily_coins_earned, daily_coins_softcap_progress, last_coin_reset_date
            `, [userId, userState.reward_day]);
            userState = updateRes.rows[0];
        }

        return userState;
    }

    /**
     * Processes a correct answer and calculates coins earned based on the Soft Cap logic.
     * Updates the user's balance and daily tracking columns.
     *
     * Rules:
     * - First 50 correct answers: 1 coin each (1:1 ratio)
     * - Answers 51+: 1 coin per 5 correct answers (1:5 ratio)
     *
     * @param {Object} client Database client
     * @param {number} userId
     * @param {string} rewardDay UTC date returned by the locked reward ledger write
     * @returns {number} The amount of coins earned (0 or 1)
     */
    async processQuizCoinReward(client, userId, rewardDay) {
        const state = await this.ensureDailyReset(client, userId, rewardDay);

        let coinsToAward = 0;
        let newEarned = state.daily_coins_earned;
        let newProgress = state.daily_coins_softcap_progress;

        // Soft Cap Threshold
        if (state.daily_coins_earned < 50) {
            // 1:1 Ratio Phase
            coinsToAward = 1;
            newEarned += 1;
            // Progress remains 0 during 1:1 phase
        } else {
            // 1:5 Ratio Phase (Soft Cap)
            newProgress += 1;
            if (newProgress >= 5) {
                coinsToAward = 1;
                newEarned += 1;
                newProgress = 0; // Reset progress bar
            }
        }

        // Apply Updates
        await client.query(`
            UPDATE users
            SET daily_coins_earned = $1,
                daily_coins_softcap_progress = $2,
                coins = coins + $3
            WHERE id = $4
        `, [newEarned, newProgress, coinsToAward, userId]);

        return coinsToAward;
    }

    async dailyProgress(client, userId) {
        const result = await client.query(`
            WITH clock AS (SELECT (NOW() AT TIME ZONE 'UTC')::date AS today),
            day AS (
                SELECT today, today::timestamp AT TIME ZONE 'UTC' AS starts,
                       (today + 1)::timestamp AT TIME ZONE 'UTC' AS ends FROM clock
            ),
            daily AS (
                SELECT r.id, r.question_id, r.session_id, r.is_correct, r.created_at FROM responses r, day
                WHERE r.created_at >= starts AND r.created_at < ends
                  AND (r.user_id = $1 OR (r.user_id IS NULL AND EXISTS (
                      SELECT 1 FROM quiz_sessions s WHERE s.id = r.session_id AND s.user_id = $1
                  )))
            ), ordered AS (
                SELECT d.*, row_number() OVER (PARTITION BY s.id ORDER BY d.created_at, d.id) AS position
                FROM daily d JOIN quiz_sessions s ON s.id = d.session_id AND s.user_id = $1, day
                WHERE s.started_at >= starts AND s.started_at < ends
            ), rounds AS (
                SELECT count(*)::int AS progress FROM ordered WHERE position <= 5 GROUP BY session_id
                HAVING bool_and(is_correct IS TRUE) AND count(DISTINCT question_id) = count(*)
            )
            SELECT today::text AS date,
                (SELECT count(DISTINCT question_id)::int FROM daily) AS daily_1,
                (SELECT count(DISTINCT question_id)::int FROM daily WHERE is_correct) AS daily_2,
                (SELECT coalesce(max(progress), 0) FROM rounds) AS daily_3,
                ARRAY(SELECT split_part(quest_id, '_', 1) || '_' || split_part(quest_id, '_', 2)
                      FROM user_claimed_quests WHERE user_id = $1
                      AND (quest_id ~ ('^daily_[123]_' || today::text || '$')
                           OR (quest_id ~ '^daily_[123]_[0-9]{13}$'
                               AND claimed_at >= starts AND claimed_at < ends))) AS claimed
            FROM day`, [userId]);
        const row = result.rows[0];
        const quests = dailyQuests.map(quest => {
            const currentCount = Math.min(row[quest.id], quest.targetCount);
            const status = row.claimed.includes(quest.id) ? 'claimed' :
                currentCount >= quest.targetCount ? 'completed' : 'active';
            return { ...quest, currentCount, status };
        });
        return { date: row.date, quests };
    }

    async processQuestClaim(client, userId, requestedId, { expectedDate } = {}) {
        // Older clients append their own timestamp. It never identifies the claim.
        const match = typeof requestedId === 'string' && /^(daily_[123])(?:_\d{13})?$/.exec(requestedId);
        if (!match) throw new AppError('Unknown daily quest', 400);
        const progress = await this.dailyProgress(client, userId);
        if (expectedDate !== undefined && expectedDate !== progress.date) {
            throw new AppError('Daily quest date has changed', 409);
        }
        const quest = progress.quests.find(q => q.id === match[1]);
        if (quest.status === 'active') throw new AppError('Daily quest is incomplete', 409);

        if (quest.status === 'completed') {
            const claim = await client.query(
                'INSERT INTO user_claimed_quests (user_id, quest_id) VALUES ($1,$2) ON CONFLICT DO NOTHING',
                [userId, `${quest.id}_${progress.date}`]
            );
            if (claim.rowCount) {
                const balance = await client.query('UPDATE users SET coins = coins + $1 WHERE id = $2 RETURNING coins',
                    [quest.rewardTokens, userId]);
                return { success: true, date: progress.date, awardedTokens: quest.rewardTokens, newBalance: balance.rows[0].coins };
            }
        }
        const balance = await client.query('SELECT coins FROM users WHERE id = $1', [userId]);
        return { success: true, date: progress.date, awardedTokens: 0, newBalance: balance.rows[0].coins };
    }
}

module.exports = new EconomyService();
