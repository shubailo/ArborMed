"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireRole = exports.requireAuth = void 0;
// import jwt from 'jsonwebtoken';
const requireAuth = (req, res, next) => {
    // For Alpha, we'll ALWAYS provide a mock user if not properly authenticated
    // In production, this would verify a JWT and set req.user
    const authHeader = req.headers.authorization;
    console.log(`[AUTH] ${req.method} ${req.url}`);
    req.user = {
        id: "ae30193e-83b3-c392-1192-9cad0e1f2031",
        role: "STUDENT",
        organizationId: "med-uni-01"
    };
    console.log(`[AUTH] Set mock user: ${req.user.id}`);
    if (authHeader && authHeader.startsWith('Bearer ')) {
        // Here we could extract real user data from token if we wanted
        // const token = authHeader.split(' ')[1];
    }
    next();
};
exports.requireAuth = requireAuth;
const requireRole = (roles) => {
    return (req, res, next) => {
        const user = req.user;
        if (!user || !roles.includes(user.role)) {
            return res.status(403).json({ error: 'Access denied: insufficient permissions' });
        }
        next();
    };
};
exports.requireRole = requireRole;
