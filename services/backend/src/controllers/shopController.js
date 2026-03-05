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

    // 1. Get Item Price
    const itemResult = await db.query('SELECT * FROM items WHERE id = $1', [itemId]);
    if (itemResult.rows.length === 0) {
        return next(new AppError('Item not found', 404));
    }
    const item = itemResult.rows[0];

    // 2. Transaction
    // ⚡ Bolt: Transaction Connection Fix
    // What: Replaced raw `db.query('BEGIN')` calls with `withTransaction`.
    // Why: Raw db.query gets a random connection from the pool. Calling BEGIN and COMMIT on different db.query calls can execute them on different connections, causing silent failures, partial commits, and connection leaks.
    // Impact: Fixes a severe bug where transactions could leak or fail, improving stability and connection pool efficiency.
    // Measurement: Verified by observing predictable connection checkout/release in pg pool instead of orphaned transactions.
    const { userItemId, newBalance } = await withTransaction(async (client) => {
        // Atomic Update: Deduct Coins ONLY if sufficient balance
        const updateRes = await client.query(
            'UPDATE users SET coins = coins - $1 WHERE id = $2 AND coins >= $1 RETURNING coins',
            [item.price, userId]
        );

        if (updateRes.rowCount === 0) {
            throw new AppError('Insufficient coins', 400);
        }

        const newBalance = updateRes.rows[0].coins;

        // Add to Inventory
        const inventoryRes = await client.query(
            'INSERT INTO user_items (user_id, item_id) VALUES ($1, $2) RETURNING id',
            [userId, itemId]
        );
        const userItemId = inventoryRes.rows[0].id;

        return { userItemId, newBalance };
    });

    res.json({
        message: 'Item purchased',
        userItemId,
        newBalance
    });
});

exports.saveAvatar = catchAsync(async (req, res, next) => {
    const userId = req.user.id;
    const { config, buy_items } = req.body;
    console.log(`[AvatarSave] User ${userId} attempting to save. Items to buy:`, buy_items);
    console.log(`[AvatarSave] Config:`, JSON.stringify(config));

    if (!config) {
        console.error('[AvatarSave] Failed: No config provided');
        return next(new AppError('No config provided', 400));
    }

    const { newBalance, updatedUser } = await withTransaction(async (client) => {
        let totalCost = 0;

        // 1. Process purchases if any
        if (buy_items && buy_items.length > 0) {
            // Get prices for all items to buy
            const itemsRes = await client.query(
                'SELECT id, price FROM items WHERE id = ANY($1)',
                [buy_items]
            );

            if (itemsRes.rows.length !== buy_items.length) {
                throw new AppError('One or more items not found in catalog', 404);
            }

            totalCost = itemsRes.rows.reduce((sum, item) => sum + item.price, 0);

            // Verify and deduct balance
            const userUpdate = await client.query(
                'UPDATE users SET coins = coins - $1 WHERE id = $2 AND coins >= $1 RETURNING coins',
                [totalCost, userId]
            );

            if (userUpdate.rowCount === 0) {
                throw new AppError('Insufficient coins for this combination', 400);
            }

            // Grant ownership
            for (const itemId of buy_items) {
                await client.query(
                    'INSERT INTO user_items (user_id, item_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
                    [userId, itemId]
                );
            }
        }

        // 2. Update Avatar Config
        const finalUpdate = await client.query(
            'UPDATE users SET avatar_config = $1 WHERE id = $2 RETURNING *',
            [config, userId]
        );

        return {
            newBalance: totalCost > 0 ? userUpdate.rows[0].coins : finalUpdate.rows[0].coins,
            updatedUser: finalUpdate.rows[0]
        };
    });

    res.json({
        success: true,
        message: 'Avatar configuration saved',
        newBalance,
        avatarConfig: updatedUser.avatar_config
    });
});

