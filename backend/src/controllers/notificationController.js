const db = require('../config/db');

/**
 * @desc Get user's inbox (PAGER) - Merged notifications and peer notes
 */
exports.getInbox = async (req, res) => {
    const userId = req.user.id;
    try {
        // Fetch Admin/System Notifications
        const notifs = await db.query(`
            SELECT n.id, n.message, n.type, n.is_read, n.created_at, u.username as sender_name
            FROM notifications n
            LEFT JOIN users u ON n.sender_id = u.id
            WHERE n.user_id = $1
            ORDER BY n.created_at DESC
            LIMIT 50
        `, [userId]);

        // Fetch Peer Consultation Notes
        const notes = await db.query(`
            SELECT n.id, n.note as message, 'peer_note' as type, FALSE as is_read, n.created_at, u.username as sender_name
            FROM consultation_notes n
            JOIN users u ON n.author_id = u.id
            WHERE n.target_user_id = $1
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
