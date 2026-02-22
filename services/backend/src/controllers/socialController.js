const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

/**
 * @desc Search users by handle or Medical ID
 * @route GET /api/social/search
 */
exports.searchUsers = catchAsync(async (req, res, next) => {
    const { query } = req.query;
    if (!query) return next(new AppError('Search query required', 400));

    const userId = req.user.id;

    // Search by handle (partial) or ID (exact)
    const sql = `
        SELECT id, username, display_name, streak_count, xp, level
        FROM users
        WHERE (username ILIKE $1 OR id::text = $2)
          AND id != $3
        LIMIT 10
    `;

    const result = await db.query(sql, [`%${query}%`, query, userId]);

    // Add friendship status to results
    const users = await Promise.all(result.rows.map(async (u) => {
        const statusCheck = await db.query(
            'SELECT status, requester_id FROM friendships WHERE (requester_id = $1 AND receiver_id = $2) OR (requester_id = $2 AND receiver_id = $1)',
            [userId, u.id]
        );

        let friendshipStatus = 'none';
        if (statusCheck.rows.length > 0) {
            const f = statusCheck.rows[0];
            if (f.status === 'accepted') {
                friendshipStatus = 'colleague';
            } else {
                friendshipStatus = f.requester_id === userId ? 'request_sent' : 'request_received';
            }
        }

        return { ...u, friendshipStatus };
    }));

    res.json(users);
});

/**
 * @desc Send friend request
 * @route POST /api/social/request
 */
exports.sendRequest = catchAsync(async (req, res, next) => {
    const { receiverId } = req.body;
    const requesterId = req.user.id;

    if (requesterId === parseInt(receiverId)) {
        return next(new AppError('Cannot add yourself', 400));
    }

    // Check if already exists
    const check = await db.query(
        'SELECT * FROM friendships WHERE (requester_id = $1 AND receiver_id = $2) OR (requester_id = $2 AND receiver_id = $1)',
        [requesterId, receiverId]
    );

    if (check.rows.length > 0) {
        return next(new AppError('Relationship already exists or pending', 400));
    }

    await db.query(
        'INSERT INTO friendships (requester_id, receiver_id, status) VALUES ($1, $2, $3)',
        [requesterId, receiverId, 'pending']
    );

    res.status(201).json({ message: 'Consultation request sent' });
});

/**
 * @desc Respond to friend request (accept/decline)
 * @route PUT /api/social/request
 */
exports.respondToRequest = catchAsync(async (req, res, next) => {
    const { requesterId, action } = req.body; // action: 'accept' or 'decline'
    const receiverId = req.user.id;

    if (action === 'accept') {
        const result = await db.query(
            'UPDATE friendships SET status = $1, updated_at = NOW() WHERE requester_id = $2 AND receiver_id = $3 RETURNING *',
            ['accepted', requesterId, receiverId]
        );

        if (result.rows.length === 0) {
            return next(new AppError('Request not found', 404));
        }
        res.json({ message: 'Consultation request accepted' });
    } else {
        await db.query(
            'DELETE FROM friendships WHERE requester_id = $2 AND receiver_id = $1 AND status = $3',
            [receiverId, requesterId, 'pending']
        );
        res.json({ message: 'Request declined' });
    }
});

/**
 * @desc Get user's network (colleagues and pending)
 * @route GET /api/social/network
 */
exports.getNetwork = catchAsync(async (req, res, next) => {
    const userId = req.user.id;

    // Accepted colleagues
    const colleaguesResult = await db.query(`
        SELECT u.id, u.username, u.display_name, u.streak_count, u.xp, u.level
        FROM users u
        JOIN friendships f ON (f.requester_id = u.id OR f.receiver_id = u.id)
        WHERE (f.requester_id = $1 OR f.receiver_id = $1)
          AND f.status = 'accepted'
          AND u.id != $1
    `, [userId]);

    // Inject System Bot (Dr. Hemmy)
    const botResult = await db.query('SELECT id, username, display_name, streak_count, xp, level FROM users WHERE id = 999');
    if (botResult.rows.length > 0 && userId !== 999) {
        colleaguesResult.rows.push(botResult.rows[0]);
    }

    // Pending incoming
    const pendingResult = await db.query(`
        SELECT u.id, u.username, u.display_name, u.streak_count, u.xp, u.level
        FROM users u
        JOIN friendships f ON f.requester_id = u.id
        WHERE f.receiver_id = $1 AND f.status = 'pending'
    `, [userId]);

    res.json({
        colleagues: colleaguesResult.rows,
        pending: pendingResult.rows
    });
});

/**
 * @desc Leave a consultation note on a user's room
 * @route POST /api/social/note
 */
exports.leaveNote = catchAsync(async (req, res, next) => {
    const { targetUserId, note } = req.body;
    const authorId = req.user.id;

    if (!note) return next(new AppError('Note content is required', 400));

    // Verify they are colleagues
    const colleagueCheck = await db.query(
        "SELECT * FROM friendships WHERE ((requester_id = $1 AND receiver_id = $2) OR (requester_id = $2 AND receiver_id = $1)) AND status = 'accepted'",
        [authorId, targetUserId]
    );

    if (colleagueCheck.rows.length === 0) {
        return next(new AppError('Only colleagues can leave consultation notes', 403));
    }

    await db.query(
        'INSERT INTO consultation_notes (author_id, target_user_id, note) VALUES ($1, $2, $3)',
        [authorId, targetUserId, note]
    );

    res.status(201).json({ message: 'Note posted successfully' });
});

/**
 * @desc Get notes for a user's room
 * @route GET /api/social/notes/:userId
 */
exports.getNotes = catchAsync(async (req, res, next) => {
    const { userId } = req.params;
    const requesterId = req.user.id;

    // Verify IDOR: User can only see notes left for themselves OR if they are an ADMIN
    if (parseInt(userId) !== requesterId && req.user.role !== 'admin') {
        return next(new AppError('You can only view your own room notes', 403));
    }

    const result = await db.query(`
        SELECT n.note, n.created_at, u.username, u.display_name
        FROM consultation_notes n
        JOIN users u ON n.author_id = u.id
        WHERE n.target_user_id = $1
          AND n.created_at > NOW() - INTERVAL '7 days'
        ORDER BY n.created_at DESC
    `, [userId]);

    res.json(result.rows);
});

/**
 * @desc Like a user's room (reward 5 coins)
 * @route POST /api/social/like
 */
exports.likeRoom = catchAsync(async (req, res, next) => {
    const client = await db.pool.connect();
    try {
        const { targetUserId } = req.body;
        const authorId = req.user.id;

        if (authorId === parseInt(targetUserId)) {
            return next(new AppError('Cannot like your own room', 400));
        }

        await client.query('BEGIN');

        try {
            await client.query(
                'INSERT INTO room_likes (liker_id, receiver_id) VALUES ($1, $2)',
                [authorId, targetUserId]
            );
        } catch (err) {
            if (err.code === '23505') {
                await client.query('ROLLBACK');
                return next(new AppError('You have already liked this room!', 400));
            }
            throw err;
        }

        await client.query('UPDATE users SET coins = coins + 5 WHERE id = $1', [targetUserId]);
        await client.query('COMMIT');
        res.json({ message: 'Reward sent to colleague!' });
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
});

/**
 * @desc Remove a colleague (unfriend)
 * @route DELETE /api/social/colleague/:targetUserId
 */
exports.removeColleague = catchAsync(async (req, res, next) => {
    const { targetUserId } = req.params;
    const userId = req.user.id;

    await db.query(
        'DELETE FROM friendships WHERE (requester_id = $1 AND receiver_id = $2) OR (requester_id = $2 AND receiver_id = $1)',
        [userId, targetUserId]
    );

    res.json({ message: 'Colleague removed' });
});
