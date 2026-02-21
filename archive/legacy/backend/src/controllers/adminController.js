const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

/**
 * @desc Get all students (non-admins) with pagination and search
 */
exports.getStudents = catchAsync(async (req, res, next) => {
    const { page = 1, limit = 50, search = '' } = req.query;
    const offset = (page - 1) * limit;
    const params = [];
    let whereClause = "WHERE role = 'student' AND email NOT IN ('endre@medbuddy.ai')";

    if (search) {
        params.push(`%${search}%`);
        whereClause += ` AND email ILIKE $${params.length}`;
    }

    const countQuery = `SELECT COUNT(*) FROM users ${whereClause}`;
    const dataQuery = `
        SELECT id, email, role, created_at 
        FROM users 
        ${whereClause} 
        ORDER BY created_at DESC 
        LIMIT $${params.length + 1} OFFSET $${params.length + 2}
    `;

    const [countResult, dataResult] = await Promise.all([
        db.query(countQuery, params),
        db.query(dataQuery, [...params, limit, offset])
    ]);

    res.json({
        users: dataResult.rows,
        total: parseInt(countResult.rows[0].count),
        page: parseInt(page),
        limit: parseInt(limit)
    });
});

/**
 * @desc Get all administrators with pagination and search
 */
exports.getAdmins = catchAsync(async (req, res, next) => {
    const { page = 1, limit = 50, search = '' } = req.query;
    const offset = (page - 1) * limit;
    const params = [];
    let whereClause = "WHERE role = 'admin'";

    if (search) {
        params.push(`%${search}%`);
        whereClause += ` AND email ILIKE $${params.length}`;
    }

    const countQuery = `SELECT COUNT(*) FROM users ${whereClause}`;
    const dataQuery = `
        SELECT id, email, role, created_at, assigned_subject_id
        FROM users 
        ${whereClause} 
        ORDER BY created_at DESC 
        LIMIT $${params.length + 1} OFFSET $${params.length + 2}
    `;

    const [countResult, dataResult] = await Promise.all([
        db.query(countQuery, params),
        db.query(dataQuery, [...params, limit, offset])
    ]);

    res.json({
        users: dataResult.rows,
        total: parseInt(countResult.rows[0].count),
        page: parseInt(page),
        limit: parseInt(limit)
    });
});

/**
 * @desc Promote student to admin or demote admin to student
 */
exports.updateUserRole = catchAsync(async (req, res, next) => {
    const { userId, newRole } = req.body;
    const currentUserEmail = req.user.email;

    // 🔒 SUPER ADMIN ONLY
    if (currentUserEmail !== process.env.SUPER_ADMIN_EMAIL) {
        return next(new AppError('Only the Super Admin can change user roles.', 403));
    }

    if (!['student', 'admin'].includes(newRole)) {
        return next(new AppError('Invalid role', 400));
    }

    const result = await db.query(
        "UPDATE users SET role = $1 WHERE id = $2 RETURNING id, email, role",
        [newRole, userId]
    );

    if (result.rows.length === 0) {
        return next(new AppError('User not found', 404));
    }

    res.json({ message: `User updated to ${newRole}`, user: result.rows[0] });
});

/**
 * @desc Delete a user account (Cascading deletes handle dependencies)
 */
exports.deleteUser = catchAsync(async (req, res, next) => {
    const { userId } = req.params;
    const currentUserEmail = req.user.email;

    // 🔒 SUPER ADMIN ONLY
    if (currentUserEmail !== process.env.SUPER_ADMIN_EMAIL) {
        return next(new AppError('Only the Super Admin can delete users.', 403));
    }

    if (parseInt(userId) === req.user.id) {
        return next(new AppError('Cannot delete your own account', 400));
    }

    const client = await db.pool.connect();

    try {
        await client.query('BEGIN');

        // 1. Delete dependent Quiz Responses first (via sessions)
        await client.query(`
            DELETE FROM responses 
            WHERE session_id IN (SELECT id FROM quiz_sessions WHERE user_id = $1)
        `, [userId]);

        // 2. Delete Quiz Sessions
        await client.query('DELETE FROM quiz_sessions WHERE user_id = $1', [userId]);

        // 4. Delete User
        const result = await client.query("DELETE FROM users WHERE id = $1 RETURNING id", [userId]);

        if (result.rows.length === 0) {
            await client.query('ROLLBACK');
            return next(new AppError('User not found', 404));
        }

        await client.query('COMMIT');
        res.json({ message: 'User and all related data deleted successfully' });
    } catch (err) {
        await client.query('ROLLBACK');
        throw err;
    } finally {
        client.release();
    }
});

/**
 * @desc Send a direct message (Notification) to a user
 */
exports.sendDirectMessage = catchAsync(async (req, res, next) => {
    const { userId, message } = req.body;
    const adminId = req.user.id;

    if (!message || message.trim().length === 0) {
        return next(new AppError('Message content required', 400));
    }

    const result = await db.query(
        "INSERT INTO notifications (user_id, sender_id, message, type) VALUES ($1, $2, $3, 'admin_alert') RETURNING id",
        [userId, adminId, message]
    );

    res.status(201).json({ message: 'Message sent successfully', notificationId: result.rows[0].id });
});

/**
 * @desc Assign subject to admin (Super Admin Only)
 */
exports.assignSubjectToAdmin = catchAsync(async (req, res, next) => {
    const { adminId, subjectId } = req.body;
    const currentUserEmail = req.user.email;

    if (currentUserEmail !== process.env.SUPER_ADMIN_EMAIL) {
        return next(new AppError('Only super admin can assign subjects', 403));
    }

    const result = await db.query(
        "UPDATE users SET assigned_subject_id = $1 WHERE id = $2 AND role = 'admin' RETURNING id, email, assigned_subject_id",
        [subjectId || null, adminId]
    );

    if (result.rows.length === 0) {
        return next(new AppError('Admin not found', 404));
    }

    res.json({ message: 'Subject assigned successfully', user: result.rows[0] });
});
