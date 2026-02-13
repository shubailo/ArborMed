/**
 * Utility to wrap async express handlers and catch errors
 * passing them to the next() middleware.
 */
module.exports = fn => {
    return (req, res, next) => {
        fn(req, res, next).catch(next);
    };
};
