const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');
const { withTransaction } = require('../utils/dbHelpers');

exports.getInventory = catchAsync(async (req, res) => {
    const targetUserId = req.query.userId || req.user.id;

    const result = await db.query(`
        SELECT ui.*, i.name, i.type, i.slot_type, i.asset_path, i.price, i.theme, i.description
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

function intValue(value) {
    if (typeof value !== 'number' && (typeof value !== 'string' || !/^-?\d+$/.test(value))) return null;
    const n = Number(value);
    return Number.isInteger(n) && n >= -2147483648 && n <= 2147483647 ? n : null;
}

function placement(item) {
    const id = intValue(item?.userItemId);
    const slot = item?.slot ?? 'floor';
    const grid = item?.x != null || item?.y != null;
    const x = grid ? intValue(item?.x) : 0;
    const y = grid ? intValue(item?.y) : 0;
    if (!id || id < 0 || typeof slot !== 'string' || !slot.trim() || slot.length > 50 || x === null || y === null) {
        throw new AppError('Invalid inventory placement', 400);
    }
    return {id, slot, x, y, grid};
}

async function ownedRoom(client, user, id) {
    // Different rooms can simultaneously move the same item. Lock the owner first.
    await client.query('SELECT id FROM users WHERE id = $1 FOR UPDATE', [user]);
    if (id == null) {
        const room = await client.query(`INSERT INTO user_rooms (user_id, room_type, is_active)
            VALUES ($1, 'exam', true) ON CONFLICT (user_id, room_type) DO UPDATE SET is_active = true RETURNING id`, [user]);
        return room.rows[0].id;
    }
    const roomId = intValue(id);
    if (!roomId || roomId < 0) throw new AppError('Invalid room', 400);
    const room = await client.query('SELECT id FROM user_rooms WHERE id = $1 AND user_id = $2 FOR UPDATE', [roomId, user]);
    if (!room.rows.length) throw new AppError('Room not found', 404);
    return room.rows[0].id;
}

const unplace = 'UPDATE user_items SET is_placed = false, placed_at_room_id = NULL, placed_at_slot = NULL, uses_grid = false';

exports.equipItem = catchAsync(async (req, res) => {
    const user = req.user.id;
    const {id, slot, grid, x, y} = placement(req.body);
    // Released clients use 0 (avatar) and 1 as aliases for their own exam room.
    const requested = req.body.roomId;
    const roomId = await withTransaction(async client => {
        const room = await ownedRoom(client, user, requested == null || [0, 1, '0', '1'].includes(requested) ? null : requested);
        if (grid) {
            await client.query(`${unplace} WHERE user_id = $1 AND placed_at_room_id = $2 AND uses_grid AND x_pos = $3 AND y_pos = $4`,
                [user, room, x, y]);
        } else {
            await client.query(`${unplace} WHERE user_id = $1 AND placed_at_room_id = $2 AND NOT uses_grid AND placed_at_slot = $3`,
                [user, room, slot]);
        }
        const updated = await client.query(`UPDATE user_items SET is_placed = true, placed_at_room_id = $1, placed_at_slot = $2,
            x_pos = $3, y_pos = $4, uses_grid = $5 WHERE id = $6 AND user_id = $7`, [room, slot, x, y, grid, id, user]);
        if (!updated.rowCount) throw new AppError('Item not found in inventory', 404);
        return room;
    });
    res.json({ message: 'Item equipped', roomId });
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

exports.syncRoomState = catchAsync(async (req, res) => {
    const { items, roomId } = req.body;
    const user = req.user.id;
    if (!Array.isArray(items)) throw new AppError('Invalid payload: items array required', 400);
    const placements = items.map(placement);
    const ids = placements.map(p => p.id);
    const positions = placements.map(p => p.grid ? `grid:${p.x},${p.y}` : `slot:${p.slot}`);
    if (new Set(ids).size !== ids.length || new Set(positions).size !== positions.length) {
        throw new AppError('Duplicate inventory placement', 400);
    }
    await withTransaction(async client => {
        const room = await ownedRoom(client, user, roomId);
        await client.query(`${unplace} WHERE user_id = $1 AND placed_at_room_id = $2`, [user, room]);
        if (!placements.length) return;
        const updated = await client.query(`UPDATE user_items ui SET is_placed = true, placed_at_room_id = $1,
            placed_at_slot = p.slot, x_pos = p.x, y_pos = p.y, uses_grid = p.grid
            FROM unnest($2::int[], $3::text[], $4::int[], $5::int[], $6::boolean[]) AS p(id,slot,x,y,grid)
            WHERE ui.id = p.id AND ui.user_id = $7`, [room, ids, placements.map(p => p.slot),
            placements.map(p => p.x), placements.map(p => p.y), placements.map(p => p.grid), user]);
        if (updated.rowCount !== ids.length) throw new AppError('Inventory item not found', 404);
    });
    res.json({ message: 'Room state synchronized', syncedCount: ids.length });
});
