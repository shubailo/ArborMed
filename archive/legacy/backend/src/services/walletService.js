const db = require('../config/db');

class WalletService {
    /**
     * Deduct wager from user. Returns true if successful.
     */
    static async sinkWager(userId, amount) {
        try {
            const res = await db.query(
                'UPDATE users SET coins = coins - $1 WHERE id = $2 AND coins >= $1 RETURNING coins',
                [amount, userId]
            );
            return res.rowCount > 0;
        } catch (err) {
            console.error('Wallet Error:', err);
            return false;
        }
    }

    /**
     * Award pot to winner.
     */
    static async awardPot(winnerId, amount) {
        try {
            await db.query(
                'UPDATE users SET coins = coins + $1 WHERE id = $2',
                [amount, winnerId]
            );
            return true;
        } catch (err) {
            console.error('Wallet Error:', err);
            return false;
        }
    }

    /**
     * Refund wager (e.g. if no match found and user cancels).
     */
    static async refund(userId, amount) {
        return this.awardPot(userId, amount);
    }
}

module.exports = WalletService;
