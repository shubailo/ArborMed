const jwt = require('jsonwebtoken');
const db = require('../config/db');

function verifyToken(token) {
    try {
        return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
        if (!process.env.SUPABASE_JWT_SECRET) throw error;
        return jwt.verify(token, process.env.SUPABASE_JWT_SECRET);
    }
}

const protect = async (req, res, next) => {
    const token = /^Bearer\s+(\S+)$/i.exec(req.headers.authorization || '')?.[1];
    if (!token) return res.status(401).json({ message: 'Not authorized, no token' });

    let decoded;
    try {
        decoded = verifyToken(token);
    } catch {
        return res.status(401).json({ message: 'Not authorized, token failed' });
    }
    try {
        const result = await db.query(`SELECT id, email, role, coins, xp, level FROM users
            WHERE id = $1 AND is_email_verified IS NOT FALSE AND email_session_version::text IS NOT DISTINCT FROM $2`,
            [decoded.id, decoded.emailVersion ?? null]);
        req.user = result.rows[0];
    } catch (error) {
        console.error('[AUTH] User lookup failed', error.message);
        return res.status(503).json({ message: 'Authentication service temporarily unavailable' });
    }
    if (!req.user) return res.status(401).json({ message: 'Not authorized, user not found' });
    return next();
};

module.exports = { protect };
