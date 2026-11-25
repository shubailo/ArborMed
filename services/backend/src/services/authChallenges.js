const crypto = require('crypto');
const db = require('../config/db');
const { withTransaction } = require('../utils/dbHelpers');
const { generateSecureOTP } = require('../utils/cryptoUtils');
const AppError = require('../utils/AppError');
const mail = require('./mailService');

function digest(email, purpose, otp) {
    return crypto.createHmac('sha256', process.env.JWT_SECRET)
        .update(JSON.stringify([purpose, email, otp])).digest();
}

function invalidCode() {
    return new AppError('Invalid or expired verification code', 400);
}

function ensureDelivery() {
    if (mail.isConfigured === false) {
        throw new AppError('Email delivery is unavailable. Please try again later.', 503);
    }
}

async function send(email, otp, purpose) {
    try {
        await mail.sendOTP(email, otp, purpose);
    } catch {
        throw new AppError('Email delivery is unavailable. Please try again later.', 503);
    }
}

async function register(email, username, displayName, passwordHash) {
    ensureDelivery();
    const registrationId = crypto.randomUUID();
    const otp = generateSecureOTP(6);
    const issued = await db.query(
        `INSERT INTO auth_challenges (email, purpose, registration_id, username, display_name, password_hash, otp_digest)
         VALUES ($1, 'registration', $2, $3, $4, $5, $6)
         ON CONFLICT (email, purpose) DO UPDATE SET
           registration_id = EXCLUDED.registration_id, username = EXCLUDED.username,
           display_name = EXCLUDED.display_name, password_hash = EXCLUDED.password_hash,
           otp_digest = EXCLUDED.otp_digest, attempts_left = 5,
           issued_at = EXCLUDED.issued_at, expires_at = EXCLUDED.expires_at
         WHERE auth_challenges.issued_at <= now() - interval '1 minute'`,
        [email, registrationId, username, displayName, passwordHash, digest(email, 'registration', otp)]
    );
    if (!issued.rowCount) throw new AppError('Please wait one minute before registering again.', 429);
    await send(email, otp, 'registration');
    return registrationId;
}

async function beginEmailVerification(user) {
    ensureDelivery();
    const verificationId = crypto.randomUUID();
    const otp = generateSecureOTP(6);
    const issued = await db.query(
        `INSERT INTO auth_challenges (email, purpose, user_id, registration_id, password_hash, otp_digest)
         SELECT email, 'email-verification', id, $2, password_hash, $3 FROM users
         WHERE id = $1 AND password_hash = $4 AND is_email_verified IS FALSE
         ON CONFLICT (email, purpose) DO UPDATE SET
           user_id = EXCLUDED.user_id, registration_id = EXCLUDED.registration_id, password_hash = EXCLUDED.password_hash,
           otp_digest = EXCLUDED.otp_digest, attempts_left = 5, issued_at = EXCLUDED.issued_at, expires_at = EXCLUDED.expires_at
         WHERE auth_challenges.issued_at <= now() - interval '1 minute'`,
        [user.id, verificationId, digest(user.email, 'email-verification', otp), user.password_hash]
    );
    if (!issued.rowCount) throw new AppError('Please wait one minute before signing in again.', 429);
    await send(user.email, otp, 'email-verification');
    return verificationId;
}

function validRegistrationId(id) {
    return typeof id === 'string' && /^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(id);
}

async function resend(email, registrationId, purpose = 'registration') {
    ensureDelivery();
    if (!validRegistrationId(registrationId) || !['registration', 'email-verification'].includes(purpose)) throw invalidCode();
    const otp = generateSecureOTP(6);
    const issued = await db.query(
        `UPDATE auth_challenges SET otp_digest = $3, attempts_left = 5,
             issued_at = now(), expires_at = now() + interval '10 minutes'
         WHERE email = $1 AND purpose = $4 AND registration_id = $2
             AND (purpose = 'registration' OR expires_at > now())
             AND issued_at <= now() - interval '1 minute'`,
        [email, registrationId, digest(email, purpose, otp), purpose]
    );
    if (!issued.rowCount) throw new AppError('Please wait one minute or start again.', 429);
    await send(email, otp, purpose);
}

async function requestPasswordReset(email) {
    ensureDelivery();
    const purpose = 'password-reset';
    const otp = generateSecureOTP(6);
    const result = await db.query(
        `INSERT INTO auth_challenges (email, purpose, user_id, otp_digest)
         SELECT email, $2, id, $3 FROM users WHERE email = $1
         ON CONFLICT (email, purpose) DO UPDATE SET user_id = EXCLUDED.user_id, otp_digest = EXCLUDED.otp_digest,
             issued_at = EXCLUDED.issued_at, expires_at = EXCLUDED.expires_at, attempts_left = 5
         WHERE auth_challenges.issued_at <= now() - interval '1 minute'`,
        [email, purpose, digest(email, purpose, otp)]
    );
    // Return the same acknowledgement without waiting on the recipient's mail provider.
    if (result.rowCount) {
        send(email, otp, purpose).catch(() => console.error('[AUTH] Verification email delivery failed.'));
    }
}

async function consume(email, purpose, otp, registrationId, onVerified) {
    if (typeof email !== 'string' || typeof otp !== 'string' || !/^\d{6}$/.test(otp) ||
        (purpose !== 'password-reset' && !validRegistrationId(registrationId))) throw invalidCode();
    const result = await withTransaction(async client => {
        const challenge = await client.query(
            `UPDATE auth_challenges SET attempts_left = attempts_left - 1
             WHERE email = $1 AND purpose = $2 AND registration_id IS NOT DISTINCT FROM $3::uuid
               AND attempts_left > 0 AND expires_at > now()
             RETURNING *`, [email, purpose, registrationId]
        );
        const row = challenge.rows[0];
        if (!row || !crypto.timingSafeEqual(row.otp_digest, digest(email, purpose, otp))) return null;
        const value = await onVerified(client, row);
        await client.query('DELETE FROM auth_challenges WHERE email = $1 AND purpose = $2', [email, purpose]);
        return value;
    });
    // A wrong answer still commits the attempt decrement.
    if (result === null) throw invalidCode();
    return result;
}

module.exports = { register, beginEmailVerification, resend, requestPasswordReset, consume };
