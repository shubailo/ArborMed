const jwt = require('jsonwebtoken');

function verifyAccessToken(token) {
    const claims = jwt.verify(token, process.env.JWT_SECRET, { algorithms: ['HS256'], maxAge: '15m' });
    const rawId = claims?.id;
    // The refresh endpoint historically accepted an integer or its decimal string.
    const id = typeof rawId === 'string' && /^[1-9]\d{0,9}$/.test(rawId) ? Number(rawId) : rawId;
    if (!Number.isInteger(id) || id < 1 || id > 2147483647) {
        throw new Error('Invalid ArborMed account ID');
    }
    if (claims.sessionId !== undefined &&
        (!Number.isInteger(claims.sessionId) || claims.sessionId < 1 || claims.sessionId > 2147483647)) {
        throw new Error('Invalid ArborMed session ID');
    }
    return { ...claims, id };
}

module.exports = { verifyAccessToken };
