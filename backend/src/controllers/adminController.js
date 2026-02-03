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
 * @desc Get all administrators with their question stats
 */
exports.getAdmins = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT 
                u.id, 
                u.email, 
                u.role, 
                u.created_at,
                u.assigned_subject_id,
                t.name_en as assigned_subject_name,
                t.name_hu as assigned_subject_name_hu,
                COALESCE(COUNT(DISTINCT q.id), 0) as questions_uploaded
            FROM users u
            LEFT JOIN topics t ON t.id = u.assigned_subject_id
            LEFT JOIN questions q ON q.created_by = u.id
            WHERE u.role = 'admin'
            GROUP BY u.id, u.email, u.role, u.created_at, u.assigned_subject_id, t.name_en, t.name_hu
            ORDER BY u.created_at DESC
        `);
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

/**
 * @desc Assign subject to admin (Super Admin Only)
 */
exports.assignSubjectToAdmin = async (req, res) => {
    const { adminId, subjectId } = req.body;
    const currentUserEmail = req.user.email;

    // Only super admin can assign subjects
    if (currentUserEmail !== 'shubailobeid@gmail.com') {
        return res.status(403).json({ error: 'Only super admin can assign subjects' });
    }

    try {
        const result = await db.query(
            "UPDATE users SET assigned_subject_id = $1 WHERE id = $2 AND role = 'admin' RETURNING id, email, assigned_subject_id",
            [subjectId || null, adminId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Admin not found' });
        }

        res.json({ message: 'Subject assigned successfully', user: result.rows[0] });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
};
