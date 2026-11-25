const db = require('../config/db');

async function withTransaction(fn) {
    const client = await db.pool.connect();
    let releaseError;
    try {
        await client.query('BEGIN');
        const result = await fn(client);
        await client.query('COMMIT');
        return result;
    } catch (error) {
        try {
            await client.query('ROLLBACK');
        } catch (rollbackError) {
            releaseError = rollbackError;
        }
        throw error;
    } finally {
        client.release(releaseError);
    }
}

module.exports = { withTransaction };
