"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorMiddleware = void 0;
const errorMiddleware = (err, req, res, next) => {
    console.error(`[ERROR] ${req.method} ${req.url}:`, err);
    const status = err.status || 500;
    const message = err.message || 'Internal Server Error';
    res.status(status).json({
        error: message,
        stack: process.env.NODE_ENV === 'production' ? undefined : err.stack
    });
};
exports.errorMiddleware = errorMiddleware;
