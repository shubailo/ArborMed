const jwt = require('jsonwebtoken');
const db = require('../config/db');

const protect = async (req, res, next) => {
    let token;

    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith('Bearer')
    ) {
        try {
            token = req.headers.authorization.split(' ')[1];
            
            let decoded;
            try {
                // 1. Try Internal JWT Secret
                decoded = jwt.verify(token, process.env.JWT_SECRET);
            } catch (err) {
                // 2. Fallback to Supabase JWT Secret if provided
                if (process.env.SUPABASE_JWT_SECRET) {
                    decoded = jwt.verify(token, process.env.SUPABASE_JWT_SECRET);
                } else {
                    throw err; // Re-throw if no fallback available
                }
            }

            const result = await db.query('SELECT id, email, role, coins, xp, level FROM users WHERE id = $1', [decoded.id]);
            req.user = result.rows[0];

            if (!req.user) {
                return res.status(401).json({ message: 'Not authorized, user not found' });
            }

            return next();
        } catch (error) {
            console.error(error);
            return res.status(401).json({ message: 'Not authorized, token failed' });
        }
    }

    if (!token) {
        return res.status(401).json({ message: 'Not authorized, no token' });
    }
};

module.exports = { protect };
