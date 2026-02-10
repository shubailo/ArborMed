const db = require('../config/db');

/**
 * @desc Search users by handle or Medical ID
 * @route GET /api/social/search
 */
exports.searchUsers = async (req, res) => {
    try {
        const { query } = req.query; // Query can be handle or ID
        if (!query) return res.status(400).json({ message: 'Search query required' });

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
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error searching users' });
    }
};

/**
 * @desc Send friend request
 * @route POST /api/social/request
 */
exports.sendRequest = async (req, res) => {
    try {
        const { receiverId } = req.body;
        const requesterId = req.user.id;

        if (requesterId === parseInt(receiverId)) {
            return res.status(400).json({ message: 'Cannot add yourself' });
        }

        // Check if already exists
        const check = await db.query(
            'SELECT * FROM friendships WHERE (requester_id = $1 AND receiver_id = $2) OR (requester_id = $2 AND receiver_id = $1)',
            [requesterId, receiverId]
        );

        if (check.rows.length > 0) {
            return res.status(400).json({ message: 'Relationship already exists or pending' });
        }

        await db.query(
            'INSERT INTO friendships (requester_id, receiver_id, status) VALUES ($1, $2, $3)',
            [requesterId, receiverId, 'pending']
        );

        res.status(201).json({ message: 'Consultation request sent' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error sending request' });
    }
};

/**
 * @desc Respond to friend request (accept/decline)
 * @route PUT /api/social/request
 */
exports.respondToRequest = async (req, res) => {
    try {
        const { requesterId, action } = req.body; // action: 'accept' or 'decline'
        const receiverId = req.user.id;

        if (action === 'accept') {
            const result = await db.query(
                'UPDATE friendships SET status = $1, updated_at = NOW() WHERE requester_id = $2 AND receiver_id = $3 RETURNING *',
                ['accepted', requesterId, receiverId]
            );

            if (result.rows.length === 0) {
                return res.status(404).json({ message: 'Request not found' });
            }
            res.json({ message: 'Consultation request accepted' });
        } else {
            await db.query(
                'DELETE FROM friendships WHERE requester_id = $2 AND receiver_id = $1 AND status = $3',
                [receiverId, requesterId, 'pending']
            );
            res.json({ message: 'Request declined' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error responding to request' });
    }
};

/**
 * @desc Get user's network (colleagues and pending)
 * @route GET /api/social/network
 */
exports.getNetwork = async (req, res) => {
    try {
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
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching network' });
    }
};

/**
 * @desc Leave a consultation note on a user's room
 * @route POST /api/social/note
 */
exports.leaveNote = async (req, res) => {
    try {
        const { targetUserId, note } = req.body;
        const authorId = req.user.id;

        if (!note) return res.status(400).json({ message: 'Note content is required' });

        // Verify they are colleagues
        const colleagueCheck = await db.query(
            "SELECT * FROM friendships WHERE ((requester_id = $1 AND receiver_id = $2) OR (requester_id = $2 AND receiver_id = $1)) AND status = 'accepted'",
            [authorId, targetUserId]
        );

        if (colleagueCheck.rows.length === 0) {
            return res.status(403).json({ message: 'Only colleagues can leave consultation notes' });
        }

        await db.query(
            'INSERT INTO consultation_notes (author_id, target_user_id, note) VALUES ($1, $2, $3)',
            [authorId, targetUserId, note]
        );

        res.status(201).json({ message: 'Note posted successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error leaving note' });
    }
};

/**
 * @desc Get notes for a user's room
 * @route GET /api/social/notes/:userId
 */
exports.getNotes = async (req, res) => {
    try {
        const { userId } = req.params;
        const requesterId = req.user.id;

        // Verify IDOR: User can only see notes left for themselves OR if they are an ADMIN
        if (parseInt(userId) !== requesterId && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'You can only view your own room notes' });
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
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching notes' });
    }
};

/**
 * @desc Like a user's room (reward 5 coins)
 * @route POST /api/social/like
 */
exports.likeRoom = async (req, res) => {
    const client = await db.pool.connect();
    try {
        const { targetUserId } = req.body;
        const authorId = req.user.id;

        if (authorId === parseInt(targetUserId)) {
            return res.status(400).json({ message: 'Cannot like your own room' });
        }

        await client.query('BEGIN');

        // 1. Attempt to insert into room_likes (Unique constraint prevents spam)
        try {
            await client.query(
                'INSERT INTO room_likes (liker_id, receiver_id) VALUES ($1, $2)',
                [authorId, targetUserId]
            );
        } catch (err) {
            if (err.code === '23505') { // Unique violation
                await client.query('ROLLBACK');
                return res.status(400).json({ message: 'You have already liked this room!' });
            }
            throw err;
        }

        // 2. Reward 5 coins
        await client.query('UPDATE users SET coins = coins + 5 WHERE id = $1', [targetUserId]);

        await client.query('COMMIT');
        res.json({ message: 'Reward sent to colleague!' });
    } catch (error) {
        if (client) await client.query('ROLLBACK');
        console.error(error);
        res.status(500).json({ message: 'Error processing like' });
    } finally {
        if (client) client.release();
    }
};

/**
 * @desc Remove a colleague (unfriend)
 * @route DELETE /api/social/colleague/:targetUserId
 */
exports.removeColleague = async (req, res) => {
    try {
        const { targetUserId } = req.params;
        const userId = req.user.id;

        await db.query(
            'DELETE FROM friendships WHERE (requester_id = $1 AND receiver_id = $2) OR (requester_id = $2 AND receiver_id = $1)',
            [userId, targetUserId]
        );

        res.json({ message: 'Colleague removed' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error removing colleague' });
    }
};
