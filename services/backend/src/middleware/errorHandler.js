const AppError = require('../utils/AppError');

/**
 * Centralized error handling middleware.
 * Must be registered AFTER all routes in server.js.
 */
const errorHandler = (err, req, res, next) => {
    err.statusCode = err.statusCode || 500;
    err.status = err.status || 'error';

    // Log all errors
    if (err.statusCode >= 500) {
        console.error(`[ERROR] ${req.method} ${req.originalUrl}:`, err.message);
        if (process.env.NODE_ENV !== 'production') {
            console.error(err.stack);
        }
    }

    // Operational errors (expected) — send structured response
    if (err.isOperational) {
        return res.status(err.statusCode).json({
            status: err.status,
            message: err.message
        });
    }

    // Programming errors (unexpected) — don't leak details in production
    if (process.env.NODE_ENV === 'production') {
        return res.status(500).json({
            status: 'error',
            message: 'Something went wrong'
        });
    }

    // Development — send full error details
    return res.status(err.statusCode).json({
        status: err.status,
        message: err.message,
        error: err,
        stack: err.stack
    });
};

module.exports = errorHandler;
