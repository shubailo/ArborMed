const { withTransaction } = require('../utils/dbHelpers');
const AppError = require('../utils/AppError');

const crates = [
    { id: 'clinical_crate', name: 'Clinical Supply Crate', theme: 'clinical',
        cost: 50, description: 'Contains random furniture and equipment.' }
];

exports.getCrateConfig = async () => crates;

// A new purchaseId denotes a new opening. Older keyless clients can still open multiple crates.
exports.openCrate = async (userId, crateType = 'clinical', purchaseId) => {
    const crate = crates.find(entry => entry.id === crateType || entry.theme === crateType);
    if (!crate) throw new AppError('Unknown crate', 400);
    if (purchaseId !== undefined && (typeof purchaseId !== 'string' || !/^[\w.-]{1,128}$/.test(purchaseId))) {
        throw new AppError('Invalid purchaseId', 400);
    }
    return withTransaction(async client => {
        await client.query('SELECT id FROM users WHERE id = $1 FOR UPDATE', [userId]);
        if (purchaseId !== undefined) {
            const previous = await client.query(
                'SELECT crate_id, result FROM crate_purchases WHERE user_id = $1 AND purchase_id = $2', [userId, purchaseId]
            );
            if (previous.rows.length) {
                if (previous.rows[0].crate_id !== crate.id) throw new AppError('Purchase ID already used', 409);
                return previous.rows[0].result;
            }
        }
        const debit = await client.query(
            'UPDATE users SET coins = coins - $1 WHERE id = $2 AND coins >= $1 RETURNING coins', [crate.cost, userId]
        );
        if (!debit.rowCount) throw new AppError('Insufficient coins for crate', 400);
        const pool = await client.query(
            'SELECT id, name, asset_path, type FROM items WHERE theme = $1 ORDER BY RANDOM() LIMIT 1 FOR SHARE', [crate.theme]
        );
        if (!pool.rows.length) throw new AppError('This crate is currently unavailable', 409);
        const item = pool.rows[0];
        const awarded = await client.query('INSERT INTO user_items (user_id, item_id) VALUES ($1, $2) RETURNING id', [userId, item.id]);
        const result = { success: true, item, userItemId: awarded.rows[0].id, newBalance: debit.rows[0].coins };
        if (purchaseId !== undefined) {
            await client.query(
                'INSERT INTO crate_purchases (user_id, purchase_id, crate_id, result) VALUES ($1, $2, $3, $4)',
                [userId, purchaseId, crate.id, result]
            );
        }
        return result;
    });
};
