
const { withTransaction } = require('../utils/dbHelpers');

class CrateService {
    /**
     * Purchases a crate, deducts coins, and awards a random item.
     * @param {number} userId 
     * @param {string} crateType 'clinical'
     */
    async openCrate(userId, crateType = 'clinical') {
        const CRATE_COST = 50;

        return await withTransaction(async (client) => {
            // 1. Check & Deduct Coins
            const userRes = await client.query(
                "UPDATE users SET coins = coins - $1 WHERE id = $2 AND coins >= $1 RETURNING coins",
                [CRATE_COST, userId]
            );

            if (userRes.rowCount === 0) {
                throw new Error("Insufficient coins for crate");
            }

            // 2. Pick Random Item from Pool
            // We exclude items the user already owns to make it more rewarding (optional choice)
            // For now, let's just pick any item matching the theme.
            const poolRes = await client.query(
                `SELECT id, name, asset_path, type FROM items 
             WHERE theme = $1 
             ORDER BY RANDOM() LIMIT 1`,
                [crateType]
            );

            if (poolRes.rows.length === 0) {
                throw new Error(`No items found in ${crateType} crate pool`);
            }

            const awardedItem = poolRes.rows[0];

            // 3. Add to User Inventory
            await client.query(
                "INSERT INTO user_items (user_id, item_id) VALUES ($1, $2)",
                [userId, awardedItem.id]
            );

            return {
                success: true,
                item: awardedItem,
                newBalance: userRes.rows[0].coins
            };
        });
    }

    /**
     * Gets available crates and their costs.
     */
    async getCrateConfig() {
        return [
            {
                id: 'clinical_crate',
                name: 'Clinical Supply Crate',
                theme: 'clinical',
                cost: 50,
                description: 'Contains random furniture and equipment.'
            }
        ];
    }
}

module.exports = new CrateService();
