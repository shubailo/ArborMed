const { verifyAccessToken } = require('../utils/accessToken');
const { findSessionUser } = require('../services/sessionUser');

const protect = async (req, res, next) => {
    const token = /^Bearer\s+(\S+)$/i.exec(req.headers.authorization || '')?.[1];
    if (!token) return res.status(401).json({ message: 'Not authorized, no token' });

    let decoded;
    try {
        decoded = verifyAccessToken(token);
    } catch {
        return res.status(401).json({ message: 'Not authorized, token failed' });
    }
    try {
        req.user = await findSessionUser(decoded);
    } catch (error) {
        console.error('[AUTH] User lookup failed', error.message);
        return res.status(503).json({ message: 'Authentication service temporarily unavailable' });
    }
    if (!req.user) return res.status(401).json({ message: 'Not authorized, user not found' });
    return next();
};

module.exports = { protect };
