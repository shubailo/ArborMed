const db = require('../config/db');

exports.getInventory = async (req, res) => {
    try {
        const userId = req.user.id;
        // Join with items to get asset details
        const result = await db.query(`
      SELECT ui.*, i.name, i.type, i.slot_type, i.asset_path, i.price 
      FROM user_items ui
      JOIN items i ON ui.item_id = i.id
      WHERE ui.user_id = $1
    `, [userId]);

        // Map x_pos/y_pos to x/y for frontend convenience
        const items = result.rows.map(row => ({
            ...row,
            x: row.x_pos,
            y: row.y_pos
        }));

        res.json(items);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.equipItem = async (req, res) => {
    try {
        const userId = req.user.id;
        const { userItemId, roomId, slot, x, y } = req.body;
        console.log(`[Equip] Request: id=${userItemId}, slot=${slot}, room=${roomId}, x=${x}, y=${y}`);

        // 1. Verify Ownership
        const uiResult = await db.query('SELECT * FROM user_items WHERE id = $1 AND user_id = $2', [userItemId, userId]);
        if (uiResult.rows.length === 0) {
            console.log('[Equip] Item not found matching user/id');
            return res.status(404).json({ message: 'Item not found in inventory' });
        }
        const item = uiResult.rows[0];
        console.log(`[Equip] Ownership verified for item ${item.id}`);

        // 1.5. Ensure Room Exists (Auto-create if missing)
        const roomCheck = await db.query('SELECT id FROM user_rooms WHERE id = $1 AND user_id = $2', [roomId, userId]);
        if (roomCheck.rows.length === 0) {
            console.log(`[Equip] Room ${roomId} not found, creating default room...`);
            const newRoom = await db.query(`
                INSERT INTO user_rooms (user_id, room_type, is_active)
                VALUES ($1, 'exam', TRUE)
                RETURNING id
            `, [userId]);
            const createdRoomId = newRoom.rows[0].id;
            console.log(`[Equip] Created room ${createdRoomId} for user ${userId}`);

            // Update roomId to the newly created one if it was requested as 1 but doesn't exist
            if (roomId === 1 && createdRoomId !== 1) {
                console.log(`[Equip] Warning: Requested roomId=1 but created roomId=${createdRoomId}`);
            }
        }

        // 2. Transaction to Swap Items
        await db.query('BEGIN');

        // Unequip anything else in that slot for this room (if not using x,y grid) or at x,y
        if (x !== undefined && y !== undefined) {
            // Unequip anything at this exact coordinate in this room
            const unequipRes = await db.query(`
                UPDATE user_items 
                SET is_placed = FALSE, placed_at_room_id = NULL, placed_at_slot = NULL 
                WHERE user_id = $1 AND placed_at_room_id = $2 AND x_pos = $3 AND y_pos = $4
            `, [userId, roomId, x, y]);
            console.log(`[Equip] Unequipped ${unequipRes.rowCount} items at (${x},${y})`);
        } else {
            // Traditional slot-based unequip
            const unequipRes = await db.query(`
                UPDATE user_items 
                SET is_placed = FALSE, placed_at_room_id = NULL, placed_at_slot = NULL 
                WHERE user_id = $1 AND placed_at_room_id = $2 AND placed_at_slot = $3
            `, [userId, roomId, slot]);
            console.log(`[Equip] Unequipped ${unequipRes.rowCount} items from slot ${slot}`);
        }

        // Equip new item
        const equipRes = await db.query(`
        UPDATE user_items 
        SET is_placed = TRUE, placed_at_room_id = $1, placed_at_slot = $2, x_pos = $3, y_pos = $4
        WHERE id = $5
    `, [roomId, slot, x || 0, y || 0, userItemId]);
        console.log(`[Equip] Equipped Item ID ${userItemId}. Rows affected: ${equipRes.rowCount}`);

        await db.query('COMMIT');

        res.json({ message: 'Item equipped' });

    } catch (error) {
        await db.query('ROLLBACK');
        console.error('[Equip] ERROR:', error.message);
        console.error('[Equip] Stack:', error.stack);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

exports.unequipItem = async (req, res) => {
    try {
        const userId = req.user.id;
        const { userItemId } = req.body;

        const result = await db.query(
            'UPDATE user_items SET is_placed = FALSE, placed_at_room_id = NULL, placed_at_slot = NULL, x_pos = 0, y_pos = 0 WHERE id = $1 AND user_id = $2 RETURNING id',
            [userItemId, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Item not found in inventory' });
        }

        res.json({ message: 'Item removed from room' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.syncRoomState = async (req, res) => {
    try {
        const userId = req.user.id;
        const { items, roomId } = req.body; // items: [{ userItemId, x, y, slot }]

        console.log(`[Sync] Room State Sync for user ${userId}, Room ${roomId || 'Default'}`);

        if (!items || !Array.isArray(items)) {
            return res.status(400).json({ message: 'Invalid payload: items array required' });
        }

        // 1. Ensure Room Exists
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

        // 2. "Wipe" the room (Unequip all for this room)
        // We only unequip items that belong to THIS room to avoid messing up other potential rooms
        await db.query(`
            UPDATE user_items 
            SET is_placed = FALSE, placed_at_room_id = NULL, placed_at_slot = NULL
            WHERE user_id = $1 AND placed_at_room_id = $2
        `, [userId, targetRoomId]);

        // 3. Re-equip the snapshot
        if (items.length > 0) {
            // Validate and update each item
            // Note: We could do a massive CASE/WHEN update but loop is safer for verification
            for (const item of items) {
                const { userItemId, x, y, slot } = item;

                // Verify ownership implicitly by user_id check in UPDATE
                await db.query(`
                    UPDATE user_items 
                    SET is_placed = TRUE, placed_at_room_id = $1, placed_at_slot = $2, x_pos = $3, y_pos = $4
                    WHERE id = $5 AND user_id = $6
                 `, [targetRoomId, slot || 'floor', x || 0, y || 0, userItemId, userId]);
            }
        }

        await db.query('COMMIT');

        console.log(`[Sync] Successfully synced ${items.length} items for room ${targetRoomId}`);
        res.json({ message: 'Room state synchronized', syncedCount: items.length });

    } catch (error) {
        await db.query('ROLLBACK');
        console.error('[Sync] ERROR:', error);
        res.status(500).json({ message: 'Server error during sync' });
    }
};
