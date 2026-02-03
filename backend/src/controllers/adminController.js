const db = require('../config/db');

/**
 * @desc Get all students (non-admins)
 */
exports.getStudents = async (req, res) => {
    try {
        const result = await db.query(
            "SELECT id, email, role, created_at FROM users WHERE role = 'student' ORDER BY created_at DESC"
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
};

/**
 * @desc Get all administrators
 */
exports.getAdmins = async (req, res) => {
    try {
        const result = await db.query(
            "SELECT id, email, role, created_at FROM users WHERE role = 'admin' ORDER BY created_at DESC"
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
};

/**
 * @desc Promote student to admin or demote admin to student
 */
exports.updateUserRole = async (req, res) => {
    const { userId, newRole } = req.body;

    if (!['student', 'admin'].includes(newRole)) {
        return res.status(400).json({ error: 'Invalid role' });
    }

    try {
        const result = await db.query(
            "UPDATE users SET role = $1 WHERE id = $2 RETURNING id, email, role",
            [newRole, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json({ message: `User updated to ${newRole}`, user: result.rows[0] });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
};

/**
 * @desc Delete a user account (Cascading deletes handle dependencies)
 */
exports.deleteUser = async (req, res) => {
    const { userId } = req.params;

    if (parseInt(userId) === req.user.id) {
        return res.status(400).json({ error: 'Cannot delete your own account' });
    }

    try {
        const result = await db.query("DELETE FROM users WHERE id = $1 RETURNING id", [userId]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json({ message: 'User deleted successfully' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
};

/**
 * @desc Send a direct message (Notification) to a user
 */
exports.sendDirectMessage = async (req, res) => {
    const { userId, message } = req.body;
    const adminId = req.user.id;

    if (!message || message.trim().length === 0) {
        return res.status(400).json({ error: 'Message content required' });
    }

    try {
        const result = await db.query(
            "INSERT INTO notifications (user_id, sender_id, message, type) VALUES ($1, $2, $3, 'admin_alert') RETURNING id",
            [userId, adminId, message]
        );

        res.status(201).json({ message: 'Message sent successfully', notificationId: result.rows[0].id });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error (Note: Ensure notifications table is created)' });
    }
};
