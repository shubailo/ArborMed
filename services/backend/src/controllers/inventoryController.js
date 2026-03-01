const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');
const { withTransaction } = require('../utils/dbHelpers');

exports.getInventory = catchAsync(async (req, res, next) => {
    const targetUserId = req.query.userId || req.user.id;

    const result = await db.query(`
        SELECT ui.*, i.name, i.type, i.slot_type, i.asset_path, i.price 
        FROM user_items ui
        JOIN items i ON ui.item_id = i.id
        WHERE ui.user_id = $1
    `, [targetUserId]);

    const items = result.rows.map(row => ({
        ...row,
        x: row.x_pos,
        y: row.y_pos
    }));

    res.json(items);
});

exports.equipItem = catchAsync(async (req, res, next) => {
    const userId = req.user.id;
    const { userItemId, roomId, slot, x, y } = req.body;

    // 1. Verify Ownership
    const uiResult = await db.query('SELECT * FROM user_items WHERE id = $1 AND user_id = $2', [userItemId, userId]);
    if (uiResult.rows.length === 0) {
        return next(new AppError('Item not found in inventory', 404));
    }

    // 1.5. Ensure Room Exists
    const roomCheck = await db.query('SELECT id FROM user_rooms WHERE id = $1 AND user_id = $2', [roomId, userId]);
    if (roomCheck.rows.length === 0) {
        await db.query(`
            INSERT INTO user_rooms (user_id, room_type, is_active)
            VALUES ($1, 'exam', TRUE)
        `, [userId]);
    }

    // 2. Transaction to Swap Items
    await withTransaction(async (client) => {
        if (x !== undefined && y !== undefined) {
            await client.query(`
                UPDATE user_items 
                SET is_placed = FALSE, placed_at_room_id = NULL, placed_at_slot = NULL 
                WHERE user_id = $1 AND placed_at_room_id = $2 AND x_pos = $3 AND y_pos = $4
            `, [userId, roomId, x, y]);
        } else {
            await client.query(`
                UPDATE user_items 
                SET is_placed = FALSE, placed_at_room_id = NULL, placed_at_slot = NULL 
                WHERE user_id = $1 AND placed_at_room_id = $2 AND placed_at_slot = $3
            `, [userId, roomId, slot]);
        }

        await client.query(`
            UPDATE user_items 
            SET is_placed = TRUE, placed_at_room_id = $1, placed_at_slot = $2, x_pos = $3, y_pos = $4
            WHERE id = $5
        `, [roomId, slot, x || 0, y || 0, userItemId]);
    });

    res.json({ message: 'Item equipped' });
});

exports.unequipItem = catchAsync(async (req, res, next) => {
    const userId = req.user.id;
    const { userItemId } = req.body;

    const result = await db.query(
        'UPDATE user_items SET is_placed = FALSE, placed_at_room_id = NULL, placed_at_slot = NULL, x_pos = 0, y_pos = 0 WHERE id = $1 AND user_id = $2 RETURNING id',
        [userItemId, userId]
    );

    if (result.rows.length === 0) {
        return next(new AppError('Item not found in inventory', 404));
    }

    res.json({ message: 'Item removed from room' });
});

exports.syncRoomState = catchAsync(async (req, res, next) => {
    const userId = req.user.id;
    const { items, roomId } = req.body;

    if (!items || !Array.isArray(items)) {
        return next(new AppError('Invalid payload: items array required', 400));
    }

    let targetRoomId = roomId;
    if (!targetRoomId) {
        const roomCheck = await db.query('SELECT id FROM user_rooms WHERE user_id = $1 LIMIT 1', [userId]);
        if (roomCheck.rows.length > 0) {
            targetRoomId = roomCheck.rows[0].id;
        } else {
            const newRoom = await db.query(`
                INSERT INTO user_rooms (user_id, room_type, is_active)
                VALUES ($1, 'exam', TRUE)
                RETURNING id
            `, [userId]);
            targetRoomId = newRoom.rows[0].id;
        }
    }

    await withTransaction(async (client) => {
        await client.query(`
            UPDATE user_items 
            SET is_placed = FALSE, placed_at_room_id = NULL, placed_at_slot = NULL
            WHERE user_id = $1 AND placed_at_room_id = $2
        `, [userId, targetRoomId]);

        if (items.length > 0) {
            // ⚡ Bolt: Bulk Update Optimization (N+1 Prevention)
            // What: Replaced an N+1 loop of UPDATE queries with a single O(1) bulk UPDATE using PostgreSQL `unnest`.
            // Why: syncRoomState updates multiple items simultaneously. The previous implementation executed a separate query per item, causing significant overhead.
            // Impact: Reduces database roundtrips from O(N) to O(1).
            // Measurement: Faster synchronization time, particularly noticeable on slower connections or heavy load.

            const userItemIds = items.map(i => parseInt(i.userItemId)); // Ensure integers for the query cast
            const slots = items.map(i => i.slot || 'floor');
            const xPositions = items.map(i => parseInt(i.x) || 0);
            const yPositions = items.map(i => parseInt(i.y) || 0);

            await client.query(`
                UPDATE user_items AS ui
                SET
                    is_placed = TRUE,
                    placed_at_room_id = $1,
                    placed_at_slot = bulk.slot,
                    x_pos = bulk.x,
                    y_pos = bulk.y
                FROM (
                    SELECT unnest($2::int[]) AS id, unnest($3::text[]) AS slot, unnest($4::int[]) AS x, unnest($5::int[]) AS y
                ) AS bulk
                WHERE ui.id = bulk.id AND ui.user_id = $6
             `, [targetRoomId, userItemIds, slots, xPositions, yPositions, userId]);
        }
    });

    res.json({ message: 'Room state synchronized', syncedCount: items.length });
});
