const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

/**
 * @desc Get all students (non-admins) with pagination and search
 */
exports.getStudents = catchAsync(async (req, res, next) => {
    const pageNum = parseInt(req.query.page, 10) || 1;
    let limitNum = parseInt(req.query.limit, 10) || 50;
    if (limitNum > 1000) limitNum = 1000;
    const search = req.query.search || '';

    // 🛡️ Sentinel: Prevent negative or invalid limits/offsets
    if (pageNum < 1 || limitNum < 1 || limitNum > 1000) {
        return next(new AppError('Invalid pagination parameters', 400));
    }
    const offset = (pageNum - 1) * limitNum;
    const limit = limitNum;
    const page = pageNum;
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
    const pageNum = parseInt(req.query.page, 10) || 1;
    let limitNum = parseInt(req.query.limit, 10) || 50;
    if (limitNum > 1000) limitNum = 1000;
    const search = req.query.search || '';

    // 🛡️ Sentinel: Prevent negative or invalid limits/offsets
    if (pageNum < 1 || limitNum < 1 || limitNum > 1000) {
        return next(new AppError('Invalid pagination parameters', 400));
    }
    const offset = (pageNum - 1) * limitNum;
    const limit = limitNum;
    const page = pageNum;
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

const SUPER_ADMIN_DEFAULT = 'shubailobeid@gmail.com';
const isSuperAdmin = (email) => {
    const configured = process.env.SUPER_ADMIN_EMAIL;
    return email === configured || email === SUPER_ADMIN_DEFAULT;
};

/**
 * @desc Promote student to admin or demote admin to student
 */
exports.updateUserRole = catchAsync(async (req, res, next) => {
    const { userId, newRole } = req.body;
    const currentUser = req.user;

    if (!['student', 'admin'].includes(newRole)) {
        return next(new AppError('Invalid role', 400));
    }

    // Check target user's current role
    const targetUserCheck = await db.query(
        "SELECT id, email, role FROM users WHERE id = $1",
        [userId]
    );

    if (targetUserCheck.rows.length === 0) {
        return next(new AppError('User not found', 404));
    }

    const targetUser = targetUserCheck.rows[0];

    // Any admin can promote a student to admin.
    // However, only Super Admin can demote an existing admin back to student.
    if (targetUser.role === 'admin' && newRole === 'student' && !isSuperAdmin(currentUser.email)) {
        return next(new AppError('Only the Super Admin can demote administrators.', 403));
    }

    const result = await db.query(
        "UPDATE users SET role = $1 WHERE id = $2 RETURNING id, email, role",
        [newRole, userId]
    );

    res.json({ message: `User updated to ${newRole}`, user: result.rows[0] });
});

/**
 * @desc Delete a user account (Cascading deletes handle dependencies)
 */
exports.deleteUser = catchAsync(async (req, res, next) => {
    const { userId } = req.params;
    const currentUser = req.user;

    if (parseInt(userId, 10) === currentUser.id) {
        return next(new AppError('Cannot delete your own account', 400));
    }

    // Check target user
    const targetUserCheck = await db.query(
        "SELECT id, email, role FROM users WHERE id = $1",
        [userId]
    );

    if (targetUserCheck.rows.length === 0) {
        return next(new AppError('User not found', 404));
    }

    const targetUser = targetUserCheck.rows[0];

    // Regular admin can delete students. Only Super Admin can delete other admins.
    if (targetUser.role === 'admin' && !isSuperAdmin(currentUser.email)) {
        return next(new AppError('Only the Super Admin can delete administrator accounts.', 403));
    }

    const client = await db.pool.connect();

    try {
        await client.query('BEGIN');

        // 1. Delete all student responses (direct user_id)
        await client.query('DELETE FROM responses WHERE user_id = $1', [userId]);

        // 2. Delete responses via sessions
        await client.query(`
            DELETE FROM responses 
            WHERE EXISTS (
                SELECT 1 FROM quiz_sessions
                WHERE quiz_sessions.id = responses.session_id
                AND quiz_sessions.user_id = $1
            )
        `, [userId]);

        // 3. Delete Quiz Sessions
        await client.query('DELETE FROM quiz_sessions WHERE user_id = $1', [userId]);

        // 4. Delete user activity records
        await client.query('DELETE FROM user_activity WHERE user_id = $1', [userId]);

        // 5. Delete password resets
        await client.query('DELETE FROM password_resets WHERE user_id = $1', [userId]);

        // 6. Delete avatar error logs
        await client.query('DELETE FROM avatar_err_logs WHERE user_id = $1', [userId]);

        // 7. Delete cohort memberships
        await client.query('DELETE FROM cohort_members WHERE student_id = $1', [userId]);

        // 8. Delete user (Foreign keys with CASCADE will clean up notifications, user_topic_progress, user_items, room_likes, etc.)
        const result = await client.query("DELETE FROM users WHERE id = $1 RETURNING id, email", [userId]);

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

    if (!isSuperAdmin(currentUserEmail)) {
        return next(new AppError('Only the Super Admin can assign subjects to admins.', 403));
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
