const db = require('../config/db');

/**
 * @desc Get user's inbox (PAGER) - Merged notifications and peer notes
 * Filters for last 7 days only
 */
exports.getInbox = async (req, res) => {
    const userId = req.user.id;
    try {
        // Fetch Admin/System Notifications (1 week limit)
        const notifs = await db.query(`
            SELECT n.id, n.message, n.type, n.is_read, n.created_at, u.username as sender_name
            FROM notifications n
            LEFT JOIN users u ON n.sender_id = u.id
            WHERE n.user_id = $1 
              AND n.created_at > NOW() - INTERVAL '7 days'
            ORDER BY n.created_at DESC
            LIMIT 50
        `, [userId]);

        // Fetch Peer Consultation Notes (1 week limit)
        const notes = await db.query(`
            SELECT n.id, n.note as message, 'peer_note' as type, FALSE as is_read, n.created_at, u.username as sender_name
            FROM consultation_notes n
            JOIN users u ON n.author_id = u.id
            WHERE n.target_user_id = $1
              AND n.created_at > NOW() - INTERVAL '7 days'
            ORDER BY n.created_at DESC
            LIMIT 50
        `, [userId]);

        // Merge and sort
        const combined = [...notifs.rows, ...notes.rows].sort((a, b) =>
            new Date(b.created_at) - new Date(a.created_at)
        );

        res.json(combined);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
};

/**
 * @desc Mark a notification as read
 */
exports.markAsRead = async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;
    try {
        await db.query(
            "UPDATE notifications SET is_read = TRUE WHERE id = $1 AND user_id = $2",
            [id, userId]
        );
        res.json({ message: 'Marked as read' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
};

/**
 * @desc Delete a notification or note
 */
exports.deleteItem = async (req, res) => {
    const { id } = req.params;
    const { type } = req.query;
    const userId = req.user.id;

    try {
        if (type === 'peer_note') {
            await db.query(
                "DELETE FROM consultation_notes WHERE id = $1 AND target_user_id = $2",
                [id, userId]
            );
        } else {
            await db.query(
                "DELETE FROM notifications WHERE id = $1 AND user_id = $2",
                [id, userId]
            );
        }
        res.json({ message: 'Item deleted successfully' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
};
