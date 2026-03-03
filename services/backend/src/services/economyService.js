const db = require('../config/db');

class EconomyService {
    /**
     * Resets the user's daily coin tracking if the last reset date is not today.
     * Must be called within a transaction context to prevent race conditions.
     * @param {Object} client Database client
     * @param {number} userId
     * @returns {Object} User's current economy state
     */
    async ensureDailyReset(client, userId) {
        const { rows } = await client.query(`
            SELECT daily_coins_earned, daily_coins_softcap_progress, last_coin_reset_date
            FROM users
            WHERE id = $1 FOR UPDATE
        `, [userId]);

        let userState = rows[0];

        const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
        const lastReset = userState.last_coin_reset_date
            ? userState.last_coin_reset_date.toISOString().split('T')[0]
            : null;

        if (lastReset !== today) {
            const updateRes = await client.query(`
                UPDATE users
                SET daily_coins_earned = 0,
                    daily_coins_softcap_progress = 0,
                    last_coin_reset_date = CURRENT_DATE
                WHERE id = $1
                RETURNING daily_coins_earned, daily_coins_softcap_progress, last_coin_reset_date
            `, [userId]);
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
     * @returns {number} The amount of coins earned (0 or 1)
     */
    async processQuizCoinReward(client, userId) {
        const state = await this.ensureDailyReset(client, userId);

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

    /**
     * Claims a quest and awards its tokens.
     * Validates that the quest hasn't been claimed today.
     *
     * @param {Object} client Database client
     * @param {number} userId
     * @param {string} questId
     * @param {number} rewardTokens
     * @returns {Object} Result of the claim
     */
    async processQuestClaim(client, userId, questId, rewardTokens) {
        // Prevent double claiming
        const { rowCount } = await client.query(`
            SELECT 1 FROM user_claimed_quests
            WHERE user_id = $1 AND quest_id = $2
            -- Simple logic: if the quest id contains a daily timestamp,
            -- or if we reset claims nightly, this prevents immediate double click.
        `, [userId, questId]);

        if (rowCount > 0) {
            throw new Error('Quest already claimed');
        }

        // Insert Claim Record
        await client.query(`
            INSERT INTO user_claimed_quests (user_id, quest_id)
            VALUES ($1, $2)
        `, [userId, questId]);

        // Award Coins (Quests bypass the daily quiz soft cap, but add to total balance)
        const updateRes = await client.query(`
            UPDATE users
            SET coins = coins + $1
            WHERE id = $2
            RETURNING coins
        `, [rewardTokens, userId]);

        return { success: true, newBalance: updateRes.rows[0].coins };
    }
}

module.exports = new EconomyService();
