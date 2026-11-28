const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');
const { withTransaction } = require('../utils/dbHelpers');
const { positiveId } = require('../utils/quizIds');

exports.getCatalog = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { slot_type, theme } = req.query;

    let query = `
        SELECT i.*, 
               EXISTS (SELECT 1 FROM user_items ui WHERE ui.item_id = i.id AND ui.user_id = $1) as is_owned,
               (SELECT ui.id FROM user_items ui WHERE ui.item_id = i.id AND ui.user_id = $1 LIMIT 1) as user_item_id
        FROM items i 
        WHERE 1=1
    `;

    let params = [userId];
    let pIndex = 2;

    if (slot_type) {
        query += ` AND i.slot_type = $${pIndex}`;
        params.push(slot_type);
        pIndex++;
    }

    if (theme) {
        query += ` AND i.theme = $${pIndex}`;
        params.push(theme);
    }

    query += ' ORDER BY is_owned DESC, i.type, i.price';

    const result = await db.query(query, params);
    res.json(result.rows);
});

exports.buyItem = catchAsync(async (req, res) => {
    const itemId = positiveId(req.body?.itemId);
    const expectedPrice = req.body?.expectedPrice;
    if (itemId === null) throw new AppError('Invalid item ID', 400);
    if (expectedPrice !== undefined && (!Number.isSafeInteger(expectedPrice) || expectedPrice < 0)) {
        throw new AppError('Invalid expected price', 400);
    }
    const userId = req.user.id;
    const result = await withTransaction(async client => {
        // The catalog sells unlocks. Serialize purchases and crate awards on the same wallet.
        const wallet = await client.query('SELECT coins FROM users WHERE id = $1 FOR UPDATE', [userId]);
        if (!wallet.rows.length) throw new AppError('User not found', 404);
        const owned = await client.query(
            'SELECT id FROM user_items WHERE user_id = $1 AND item_id = $2 ORDER BY id LIMIT 1',
            [userId, itemId]
        );
        if (owned.rows.length) return { userItemId: owned.rows[0].id, newBalance: wallet.rows[0].coins ?? 0 };
        const item = await client.query('SELECT price FROM items WHERE id = $1 FOR SHARE', [itemId]);
        if (!item.rows.length) throw new AppError('Item not found', 404);
        const price = item.rows[0].price;
        if (price < 0 || (expectedPrice !== undefined && expectedPrice !== price)) {
            throw new AppError('The item price has changed. Refresh the catalog.', 409);
        }
        const debit = await client.query(
            'UPDATE users SET coins = COALESCE(coins, 0) - $1 WHERE id = $2 AND COALESCE(coins, 0) >= $1 RETURNING coins',
            [price, userId]
        );
        if (!debit.rowCount) throw new AppError('Insufficient coins', 400);
        const inventory = await client.query(
            'INSERT INTO user_items (user_id, item_id) VALUES ($1, $2) RETURNING id', [userId, itemId]
        );
        return { userItemId: inventory.rows[0].id, newBalance: debit.rows[0].coins };
    });
    res.json({ message: 'Item purchased', ...result });
});
