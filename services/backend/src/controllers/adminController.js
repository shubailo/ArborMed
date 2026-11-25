const { listDirectory } = require('../services/adminDirectory');
const { deliverBroadcast } = require('../services/adminBroadcast');
const { positiveId } = require('../utils/quizIds');
const db = require('../config/db');
const { withTransaction } = require('../utils/dbHelpers');
const { isSuperAdmin } = require('../utils/adminPrivileges');
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
exports.getAdmins = catchAsync(async (req, res) => {
    res.json(await listDirectory(req.query, 'admin'));
});

async function lockAdminAndTarget(client, actorId, targetId) {
    const id = Number(targetId);
    if (!Number.isSafeInteger(id) || id <= 0 || id > 2147483647) throw new AppError('Invalid user ID', 400);
    const { rows } = await client.query(
        'SELECT id, email, role, assigned_subject_id FROM users WHERE id = ANY($1::int[]) ORDER BY id FOR UPDATE',
        [[actorId, id]]
    );
    const actor = rows.find(user => user.id === actorId);
    if (actor?.role !== 'admin') throw new AppError('Administrator access required.', 403);
    const target = rows.find(user => user.id === id);
    if (!target) throw new AppError('User not found', 404);
    return { actor, target };
}

/**
 * @desc Promote student to admin or demote admin to student
 */
exports.updateUserRole = catchAsync(async (req, res, next) => {
    const { userId, newRole } = req.body;
    const currentUser = req.user;

    if (!['student', 'admin'].includes(newRole)) {
        return next(new AppError('Invalid role', 400));
    }

    const result = await withTransaction(async client => {
        const { actor, target } = await lockAdminAndTarget(client, currentUser.id, userId);
        if (target.role === 'admin' && newRole === 'student' && !isSuperAdmin(actor)) {
            throw new AppError('Only the Super Admin can demote administrators.', 403);
        }
        // An editor can delegate only their own scope. Demotion clears the old assignment.
        let subject = null;
        if (newRole === 'admin') {
            subject = target.role === 'admin' ? target.assigned_subject_id
                : isSuperAdmin(actor) ? null : actor.assigned_subject_id;
        }
        return client.query(
            'UPDATE users SET role = $1, assigned_subject_id = $2 WHERE id = $3 RETURNING id, email, role',
            [newRole, subject, target.id]);
    });

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

    await withTransaction(async client => {
        const { actor, target } = await lockAdminAndTarget(client, currentUser.id, userId);
        if (target.role === 'admin' && !isSuperAdmin(actor)) {
            throw new AppError('Only the Super Admin can delete administrator accounts.', 403);
        }

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

        // Historical installations keyed reset records by email, user ID, or both.
        const { rows: [legacy] } = await client.query(
            `SELECT EXISTS (SELECT FROM pg_attribute WHERE attrelid = to_regclass('password_resets') AND attname = 'email' AND NOT attisdropped) AS email,
                EXISTS (SELECT FROM pg_attribute WHERE attrelid = to_regclass('password_resets') AND attname = 'user_id' AND NOT attisdropped) AS user_id,
                to_regclass('avatar_err_logs') IS NOT NULL AS avatar_logs`);
        if (legacy.email) await client.query('DELETE FROM password_resets WHERE email = $1', [target.email]);
        if (legacy.user_id) await client.query('DELETE FROM password_resets WHERE user_id = $1', [target.id]);
        if (legacy.avatar_logs) await client.query('DELETE FROM avatar_err_logs WHERE user_id = $1', [target.id]);

        // Preserve the questions and audit history when an author leaves.
        await client.query('UPDATE questions SET created_by = NULL WHERE created_by = $1', [target.id]);
        await client.query(`UPDATE admin_audit_log SET admin_id = NULL,
            details = COALESCE(details, '{}'::jsonb) || jsonb_build_object('deleted_admin_id', admin_id)
            WHERE admin_id = $1`, [target.id]);

        // 7. Delete cohort memberships
        await client.query('DELETE FROM cohort_members WHERE student_id = $1', [userId]);

        // 8. Delete user (Foreign keys with CASCADE will clean up notifications, user_topic_progress, user_items, room_likes, etc.)
        await client.query('DELETE FROM users WHERE id = $1', [target.id]);
    });
    res.json({ message: 'User and all related data deleted successfully' });
});

/**
 * @desc Send a direct message (Notification) to a user
 */
exports.sendDirectMessage = catchAsync(async (req, res, next) => {
    const { userId, message } = req.body;
    const adminId = req.user.id;

    if (typeof message !== 'string' || !message.trim()) {
        return next(new AppError('Message content required', 400));
    }
    if (!positiveId(userId)) return next(new AppError('Invalid recipient', 400));

    const result = await db.query(
        `INSERT INTO notifications (user_id, sender_id, message, type)
         SELECT id, $2, $3, 'admin_alert' FROM users WHERE id = $1 RETURNING id`,
        [userId, adminId, message.trim()]
    );
    if (!result.rows.length) return next(new AppError('Recipient not found', 404));

    res.status(201).json({ message: 'Message sent successfully', notificationId: result.rows[0].id });
});

exports.broadcastMessage = catchAsync(async (req, res) => {
    const { delivered, replayed } = await deliverBroadcast(req.user.id, req.body);
    res.status(replayed ? 200 : 201).json({ delivered });
});

/**
 * @desc Assign subject to admin (Super Admin Only)
 */
exports.assignSubjectToAdmin = catchAsync(async (req, res) => {
    const { adminId, subjectId } = req.body;
    const result = await withTransaction(async client => {
        const { actor, target } = await lockAdminAndTarget(client, req.user.id, adminId);
        if (!isSuperAdmin(actor)) throw new AppError('Only the Super Admin can assign subjects to admins.', 403);
        if (target.role !== 'admin') throw new AppError('Admin not found', 404);
        return client.query(
            'UPDATE users SET assigned_subject_id = $1 WHERE id = $2 RETURNING id, email, assigned_subject_id',
            [subjectId || null, target.id]);
    });

    res.json({ message: 'Subject assigned successfully', user: result.rows[0] });
});
