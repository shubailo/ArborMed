const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');
const { withTransaction } = require('../utils/dbHelpers');

exports.getCatalog = catchAsync(async (req, res, next) => {
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

exports.buyItem = catchAsync(async (req, res, next) => {
    const userId = req.user.id;
    const { itemId } = req.body;

    // 1. Get Item Price (outside transaction is fine for static data)
    const itemResult = await db.query('SELECT * FROM items WHERE id = $1', [itemId]);
    if (itemResult.rows.length === 0) {
        return next(new AppError('Item not found', 404));
    }
    const item = itemResult.rows[0];

    // 2. Perform Transaction for balance check and inventory update
    const result = await withTransaction(async (client) => {
        // Atomic balance check and deduction
        const userUpdate = await client.query(
            'UPDATE users SET coins = coins - $1 WHERE id = $2 AND coins >= $1 RETURNING coins',
            [item.price, userId]
        );

        if (userUpdate.rowCount === 0) {
            throw new AppError('Insufficient coins', 400);
        }

        const newBalance = userUpdate.rows[0].coins;

        // Add to Inventory
        const inventoryRes = await client.query(
            'INSERT INTO user_items (user_id, item_id) VALUES ($1, $2) RETURNING id',
            [userId, itemId]
        );
        const userItemId = inventoryRes.rows[0].id;

        return {
            userItemId,
            newBalance
        };
    });

    res.json({
        message: 'Item purchased',
        ...result
    });
});

