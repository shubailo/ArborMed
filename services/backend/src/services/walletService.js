const db = require('../config/db');
const { withTransaction } = require('../utils/dbHelpers');

const allowedWagers = new Set([5, 10, 25, 50, 100]);
const insufficientFunds = new Error('Insufficient funds');
const unavailableReservation = new Error('Reservation unavailable');

function isAllowedWager(amount) {
  return allowedWagers.has(amount);
}

async function reserve(id, userId, amount, session) {
  if (!isAllowedWager(amount) || (session != null && session.id !== userId)) return false;
  try {
    return await withTransaction(async client => {
      const hold = await client.query(
        `INSERT INTO duel_wagers (id, user_id, amount, expires_at)
         VALUES ($1, $2, $3, NOW() + INTERVAL '2 minutes') ON CONFLICT DO NOTHING`,
        [id, userId, amount]
      );
      if (!hold.rowCount) return false;
      const debit = await client.query(
        `UPDATE users SET coins = coins - $2, last_activity_at = greatest(last_activity_at, statement_timestamp())
         WHERE id = $1 AND coins >= $2${session ?
          ' AND is_email_verified IS NOT FALSE AND email_session_version::text IS NOT DISTINCT FROM $3' : ''}`,
        session ? [userId, amount, session.emailVersion ?? null] : [userId, amount]
      );
      if (!debit.rowCount) throw insufficientFunds;
      return true;
    });
  } catch (error) {
    if (error === insufficientFunds) return false;
    throw error;
  }
}

async function start(matchId, holds, amount) {
  if (!isAllowedWager(amount) || !Array.isArray(holds) || holds.length < 1 || holds.length > 2) return false;
  try {
    return await withTransaction(async client => {
      // Both players must still have live holds after waiting for their row locks.
      await client.query('SELECT id FROM duel_wagers WHERE id = ANY($1::uuid[]) ORDER BY id FOR UPDATE', [holds]);
      const result = await client.query(
        `UPDATE duel_wagers SET match_id = $1, expires_at = statement_timestamp() + INTERVAL '3 minutes'
         WHERE id = ANY($2::uuid[]) AND match_id IS NULL AND closed_at IS NULL
           AND expires_at > statement_timestamp() AND amount = $3`, [matchId, holds, amount]
      );
      if (result.rowCount !== holds.length) throw unavailableReservation;
      return true;
    });
  } catch (error) {
    if (error === unavailableReservation) return false;
    throw error;
  }
}

// Updating the ledger and crediting balances in one statement means competing
// refunds and settlements can only pay rows that the winning operation closed.
async function close(where, payout, values) {
  const result = await db.query(
    `WITH closed AS (
       UPDATE duel_wagers SET payout = ${payout}, closed_at = NOW()
       WHERE closed_at IS NULL AND ${where} RETURNING user_id, payout
     ), credits AS (
       SELECT user_id, SUM(payout)::integer AS total FROM closed GROUP BY user_id
     )
     UPDATE users SET coins = COALESCE(users.coins, 0) + credits.total FROM credits
     WHERE users.id = credits.user_id RETURNING users.id AS user_id, credits.total AS payout`, values
  );
  return result.rows;
}

async function cancel(id, unannouncedMatchId = null) {
  // A failed COMMIT acknowledgement may have attached this hold to the forming match.
  return (await close('id = $1 AND (match_id IS NULL OR match_id = $2)', 'amount', [id, unannouncedMatchId])).length > 0;
}

function settlePayouts(matchId, outcome, winnerId) {
  // Recovery may skip a locked wager and refund its opponent first. Lock the
  // whole match before deciding whether any player can still receive a win.
  // clock_timestamp() checks the deadline after a lock wait, even in a long transaction.
  // A deleted account's hold cascades away. Its opponent may still lose
  // after the winner is deleted. A live outsider can never win a match.
  const validWinner = outcome === 'win' ? `AND (
      bool_or(user_id = $2)
      OR (count(*) = 1 AND ($2 IS NULL OR NOT EXISTS (SELECT FROM users WHERE id = $2)))
    )` : '';
  const eligibleMatch = `match_id = $1 AND (
    SELECT bool_and(closed_at IS NULL) AND min(expires_at) > clock_timestamp()
    ${validWinner}
    FROM (SELECT user_id, closed_at, expires_at FROM duel_wagers
          WHERE match_id = $1 ORDER BY id FOR UPDATE) AS locked
  )`;
  if (outcome === 'draw') return close(eligibleMatch, 'amount', [matchId]);
  if (outcome !== 'win') throw new Error('Unknown duel outcome');
  // A null winner identifies the server's bot, which has no wallet.
  return close(eligibleMatch,
    'CASE WHEN user_id = $2 THEN amount * 2 ELSE 0 END', [matchId, winnerId]);
}

async function settle(matchId, outcome, winnerId) {
  return (await settlePayouts(matchId, outcome, winnerId)).length > 0;
}

async function receipt(matchId, userId, session) {
  if (session != null && session.id !== userId) return undefined;
  const { rows } = await db.query(
    `SELECT amount AS wager, payout FROM duel_wagers WHERE match_id = $1 AND user_id = $2${session ?
      ' AND EXISTS (SELECT FROM users WHERE id = $2 AND is_email_verified IS NOT FALSE AND email_session_version::text IS NOT DISTINCT FROM $3)' : ''}`,
    session ? [matchId, userId, session.emailVersion ?? null] : [matchId, userId]
  );
  return rows[0];
}

async function recoverExpired() {
  return (await close(`id IN (
    SELECT id FROM duel_wagers WHERE closed_at IS NULL AND expires_at <= NOW()
    ORDER BY expires_at, id FOR UPDATE SKIP LOCKED
  )`, 'amount', [])).length > 0;
}

module.exports = { isAllowedWager, reserve, start, cancel, settle, settlePayouts, receipt, recoverExpired };
