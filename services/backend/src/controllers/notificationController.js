const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

/**
 * @desc Get user's inbox (PAGER) - Merged notifications and peer notes
 * Filters for last 7 days only
 */
exports.getInbox = catchAsync(async (req, res, next) => {
    const userId = req.user.id;

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
});

/**
 * @desc Mark a notification as read
 */
exports.markAsRead = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const userId = req.user.id;

    await db.query(
        "UPDATE notifications SET is_read = TRUE WHERE id = $1 AND user_id = $2",
        [id, userId]
    );
    res.json({ message: 'Marked as read' });
});

/**
 * @desc Delete a notification or note
 */
exports.deleteItem = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const { type } = req.query;
    const userId = req.user.id;

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
});
