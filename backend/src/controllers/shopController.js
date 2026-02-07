const db = require('../config/db');

exports.getCatalog = async (req, res) => {
    try {
        const userId = req.user.id; // Ensure auth middleware populates this
        const { slot_type, theme } = req.query;

        // Select items and check if user owns any instance of them
        let query = `
            SELECT i.*, 
                   EXISTS (SELECT 1 FROM user_items ui WHERE ui.item_id = i.id AND ui.user_id = $1) as is_owned,
                   (SELECT ui.id FROM user_items ui WHERE ui.item_id = i.id AND ui.user_id = $1 LIMIT 1) as user_item_id
            FROM items i 
            WHERE 1=1
        `;

        let params = [userId];
        let pIndex = 2; // $1 is userId

        if (slot_type) {
            query += ` AND i.slot_type = $${pIndex}`;
            params.push(slot_type);
            pIndex++;
        }

        if (theme) {
            query += ` AND i.theme = $${pIndex}`;
            params.push(theme);
            pIndex++;
        }

        query += ' ORDER BY is_owned DESC, i.type, i.price';

        const result = await db.query(query, params);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.buyItem = async (req, res) => {
    try {
        const userId = req.user.id;
        const { itemId } = req.body;

        // 1. Get Item Price
        const itemResult = await db.query('SELECT * FROM items WHERE id = $1', [itemId]);
        if (itemResult.rows.length === 0) {
            return res.status(404).json({ message: 'Item not found' });
        }
        const item = itemResult.rows[0];

        // 2. Check Use Balance
        const userResult = await db.query('SELECT coins FROM users WHERE id = $1', [userId]);
        const userCoins = userResult.rows[0].coins;

        if (userCoins < item.price) {
            return res.status(400).json({ message: 'Insufficient coins' });
        }

        // 3. Transaction
        await db.query('BEGIN');

        // Deduct Coins
        await db.query('UPDATE users SET coins = coins - $1 WHERE id = $2', [item.price, userId]);

        // Add to Inventory
        const inventoryRes = await db.query(
            'INSERT INTO user_items (user_id, item_id) VALUES ($1, $2) RETURNING id',
            [userId, itemId]
        );
        const userItemId = inventoryRes.rows[0].id;

        await db.query('COMMIT');

        res.json({
            message: 'Item purchased',
            userItemId,
            newBalance: userCoins - item.price
        });

    } catch (error) {
        await db.query('ROLLBACK');
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};
