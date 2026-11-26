const db = require('../config/db');

async function withTransaction(fn) {
    const client = await db.pool.connect();
    let releaseError;
    let transactionFinished = false;
    try {
        await client.query('BEGIN');
        const result = await fn(client);
        let commit;
        try {
            commit = await client.query('COMMIT');
            transactionFinished = true;
        } catch (cause) {
            // PostgreSQL can report a definite rejection, for example a deferred constraint.
            if (cause?.severity === 'ERROR' && cause.code !== '40003' && !cause.code?.startsWith('08'))
                throw cause;
            releaseError = cause;
            const error = new Error('Transaction outcome is unknown after COMMIT', { cause });
            error.code = 'TRANSACTION_OUTCOME_UNKNOWN';
            throw error;
        }
        if (commit?.command === 'ROLLBACK') {
            const error = new Error('PostgreSQL rolled back the transaction');
            error.code = 'TRANSACTION_ROLLED_BACK';
            throw error;
        }
        return result;
    } catch (error) {
        if (!releaseError && !transactionFinished) {
            try {
                await client.query('ROLLBACK');
            } catch (rollbackError) {
                releaseError = rollbackError;
            }
        }
        throw error;
    } finally {
        client.release(releaseError);
    }
}

module.exports = { withTransaction };
