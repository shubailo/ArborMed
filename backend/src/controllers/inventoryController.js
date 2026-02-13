const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

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
    await db.query('BEGIN');
    try {
        if (x !== undefined && y !== undefined) {
            await db.query(`
                UPDATE user_items 
                SET is_placed = FALSE, placed_at_room_id = NULL, placed_at_slot = NULL 
                WHERE user_id = $1 AND placed_at_room_id = $2 AND x_pos = $3 AND y_pos = $4
            `, [userId, roomId, x, y]);
        } else {
            await db.query(`
                UPDATE user_items 
                SET is_placed = FALSE, placed_at_room_id = NULL, placed_at_slot = NULL 
                WHERE user_id = $1 AND placed_at_room_id = $2 AND placed_at_slot = $3
            `, [userId, roomId, slot]);
        }

        await db.query(`
            UPDATE user_items 
            SET is_placed = TRUE, placed_at_room_id = $1, placed_at_slot = $2, x_pos = $3, y_pos = $4
            WHERE id = $5
        `, [roomId, slot, x || 0, y || 0, userItemId]);

        await db.query('COMMIT');
        res.json({ message: 'Item equipped' });
    } catch (error) {
        await db.query('ROLLBACK');
        throw error;
    }
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

    await db.query('BEGIN');
    try {
        await db.query(`
            UPDATE user_items 
            SET is_placed = FALSE, placed_at_room_id = NULL, placed_at_slot = NULL
            WHERE user_id = $1 AND placed_at_room_id = $2
        `, [userId, targetRoomId]);

        for (const item of items) {
            const { userItemId, x, y, slot } = item;
            await db.query(`
                UPDATE user_items 
                SET is_placed = TRUE, placed_at_room_id = $1, placed_at_slot = $2, x_pos = $3, y_pos = $4
                WHERE id = $5 AND user_id = $6
             `, [targetRoomId, slot || 'floor', x || 0, y || 0, userItemId, userId]);
        }

        await db.query('COMMIT');
        res.json({ message: 'Room state synchronized', syncedCount: items.length });
    } catch (error) {
        await db.query('ROLLBACK');
        throw error;
    }
});
