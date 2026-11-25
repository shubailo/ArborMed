const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');
const challenges = require('../services/authChallenges');
const { withTransaction } = require('../utils/dbHelpers');
const { validateEmail } = require('../utils/emailValidator');
const { auditLog } = require('./auditController');
const { OAuth2Client } = require('google-auth-library');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');
const { validatePassword, hashToken, findMatchingToken, formatUserResponse, USER_FIELDS } = require('../utils/validators');
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// 🛡️ Sentinel: Pre-computed valid hash (cost 10) for timing attack mitigation
const DUMMY_HASH = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy';

const generateToken = (id, emailVersion) => {
    return jwt.sign(emailVersion ? { id, emailVersion } : { id }, process.env.JWT_SECRET, {
        expiresIn: '15m', // Short-lived access token
    });
};

const generateRefreshToken = async (userId, client = db, passwordHash = null) => {
    const refreshToken = crypto.randomBytes(40).toString('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    // Record a successful sign-in and issue its grant under the same user-row lock.
    const inserted = await client.query(
        `WITH signed_in AS (
             UPDATE users SET last_activity_at = greatest(last_activity_at, statement_timestamp())
             WHERE id = $1 AND is_email_verified IS NOT FALSE AND ($4::text IS NULL OR password_hash = $4)
             RETURNING id
         )
         INSERT INTO refresh_tokens (user_id, token_hash, expires_at) SELECT id, $2, $3 FROM signed_in`,
        [userId, hashToken(refreshToken), expiresAt, passwordHash]
    );
    if (inserted.rowCount === 0) throw new AppError('Credentials have changed. Please sign in again.', 401);

    return refreshToken;
};

exports.register = catchAsync(async (req, res, next) => {
    const { email, password, username, display_name } = req.body;

    if (typeof email !== 'string' || !email || typeof password !== 'string' || !password) {
        return next(new AppError('Please provide email and password', 400));
    }

    if (validatePassword(password, next) !== true) return;

    // 📧 Validate Email Format & Domain
    const emailValidation = validateEmail(email);
    if (!emailValidation.isValid) {
        return next(new AppError(emailValidation.message, 400));
    }

    const finalUsername = username || email.split('@')[0].toLowerCase();
    const finalDisplayName = display_name || email.split('@')[0];
    if (email.length > 255 || typeof finalUsername !== 'string' || finalUsername.length > 255 ||
        typeof finalDisplayName !== 'string' || finalDisplayName.length > 255) {
        return next(new AppError('Invalid registration details', 400));
    }
    const existing = await db.query('SELECT email FROM users WHERE email = $1 OR username = $2', [email, finalUsername]);
    if (existing.rows.length) {
        return next(new AppError('An account with this email or username already exists. Please log in.', 400));
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const registrationId = await challenges.register(email, finalUsername, finalDisplayName, passwordHash);
    res.status(202).json({ registrationId, message: 'Check your email for the verification code.' });
});

exports.resendRegistrationOTP = catchAsync(async (req, res) => {
    const { email, registrationId } = req.body;
    await challenges.resend(email, registrationId);
    res.json({ message: 'Verification code resent.' });
});

exports.verifyRegistration = catchAsync(async (req, res) => {
    const { email, registrationId, otp } = req.body;
    const session = await challenges.consume(email, 'registration', otp, registrationId, async (client, pending) => {
        const inserted = await client.query(
            `INSERT INTO users (email, password_hash, username, display_name, is_email_verified)
             VALUES ($1, $2, $3, $4, TRUE) ON CONFLICT DO NOTHING RETURNING ${USER_FIELDS}`,
            [pending.email, pending.password_hash, pending.username, pending.display_name]
        );
        if (!inserted.rowCount) throw new AppError('An account with this email or username already exists.', 409);
        const user = inserted.rows[0];
        return { user: formatUserResponse(user), token: generateToken(user.id),
            refreshToken: await generateRefreshToken(user.id, client) };
    });
    res.status(201).json(session);
});

exports.login = catchAsync(async (req, res, next) => {
    const { email, username, password } = req.body;
    const identifier = req.body.identifier || email || username;

    if (typeof identifier !== 'string' || !identifier || identifier.length > 255 || typeof password !== 'string' || !password) {
        return next(new AppError('Please provide credentials and password', 400));
    }

    const result = await db.query(
        `SELECT ${USER_FIELDS}, password_hash, email_session_version FROM users WHERE email = $1 OR username = $1`,
        [identifier]
    );
    const user = result.rows[0];

    const validUser = !!user;
    const hashToCompare = validUser ? user.password_hash : DUMMY_HASH;

    // Always run compare to ensure consistent timing
    const isMatch = await bcrypt.compare(password, hashToCompare);

    if (validUser && isMatch) {
        if (user.is_email_verified === false) {
            const verificationId = await challenges.beginEmailVerification(user);
            return res.status(403).json({ code: 'email_not_verified', email: user.email, verificationId,
                message: 'Check your email to finish signing in.' });
        }
        const token = generateToken(user.id, user.email_session_version);
        const refreshToken = await generateRefreshToken(user.id, db, user.password_hash);

        res.json({ ...formatUserResponse(user), token, refreshToken });

        // 🛡️ Audit Log: Successful Login
        await auditLog({
            userId: user.id,
            actionType: 'LOGIN_SUCCESS',
            severity: 'INFO',
            metadata: { identifier, timestamp: new Date() },
        });
    } else {
        // 🛡️ Audit Log: Failed Login Attempt
        await auditLog({
            actionType: 'LOGIN_FAILURE',
            severity: 'WARNING',
            metadata: { identifier, timestamp: new Date() },
        });
        return next(new AppError('Invalid credentials', 401));
    }
});

exports.getMe = catchAsync(async (req, res, next) => {
    const result = await db.query(
        `SELECT ${USER_FIELDS} FROM users WHERE id = $1`,
        [req.user.id]
    );
    const row = result.rows[0];

    if (!row) {
        return next(new AppError('User not found', 404));
    }

    res.json(formatUserResponse(row));
});

exports.changePassword = catchAsync(async (req, res, next) => {
    const { currentPassword, newPassword } = req.body;

    if (typeof currentPassword !== 'string' || !currentPassword || typeof newPassword !== 'string' || !newPassword) {
        return next(
            new AppError('Please provide both current and new passwords', 400)
        );
    }

    if (validatePassword(newPassword, next) !== true) return;

    const result = await db.query(
        'SELECT password_hash FROM users WHERE id = $1',
        [req.user.id]
    );
    const user = result.rows[0];

    // 🛡️ Sentinel: Mitigate timing attacks by always performing a comparison
    const validUser = !!user;
    const hashToCompare = validUser ? user.password_hash : DUMMY_HASH;

    // Always run compare to ensure consistent timing
    const isMatch = await bcrypt.compare(currentPassword, hashToCompare);

    if (!validUser || !isMatch) {
        return next(new AppError('Incorrect current password', 400));
    }

    const salt = await bcrypt.genSalt(10);
    const hashedNewPassword = await bcrypt.hash(newPassword, salt);

    await withTransaction(async client => {
        // Match the recovery transaction's lock order: challenge, then user.
        await client.query("DELETE FROM auth_challenges WHERE user_id = $1 AND purpose = 'password-reset'", [req.user.id]);
        const updated = await client.query(
            'UPDATE users SET password_hash = $1, email_session_version = $4 WHERE id = $2 AND password_hash = $3',
            [hashedNewPassword, req.user.id, user.password_hash, crypto.randomUUID()]
        );
        if (!updated.rowCount) throw new AppError('Credentials have changed. Please sign in again.', 401);
        await client.query('UPDATE refresh_tokens SET revoked = TRUE WHERE user_id = $1 AND revoked = FALSE', [req.user.id]);
    });

    // 🛡️ Audit Log: Password Change
    await auditLog({
        userId: req.user.id,
        actionType: 'PASSWORD_CHANGE',
        severity: 'PROTECTED',
        metadata: { timestamp: new Date() },
    });

    res.json({ message: 'Password updated successfully' });
});

exports.updateProfile = catchAsync(async (req, res, next) => {
    const { username, display_name } = req.body;

    // Check if username is taken if changing it
    if (username) {
        const check = await db.query(
            'SELECT id FROM users WHERE username = $1 AND id != $2',
            [username, req.user.id]
        );
        if (check.rows.length > 0) {
            return next(new AppError('Username is already taken', 400));
        }
    }

    const result = await db.query(
        'UPDATE users SET username = COALESCE($1, username), display_name = COALESCE($2, display_name) WHERE id = $3 RETURNING username, display_name',
        [username, display_name, req.user.id]
    );

    res.json(result.rows[0]);
});

exports.requestOTP = catchAsync(async (req, res, next) => {
    const { email, purpose = 'password-reset' } = req.body;
    if (typeof email !== 'string' || !email || !['password-reset', 'email-verification'].includes(purpose)) {
        return next(new AppError('Please provide a valid email and request type', 400));
    }
    if (purpose === 'email-verification') {
        await challenges.resend(email, req.body.verificationId, purpose);
    } else {
        await challenges.requestPasswordReset(email);
    }
    res.json({ message: 'If this email is registered, a code has been sent.' });
});

exports.resetPassword = catchAsync(async (req, res, next) => {
    const { email, otp, newPassword } = req.body;
    if (typeof newPassword !== 'string' || !newPassword) return next(new AppError('Please provide a new password', 400));
    if (validatePassword(newPassword, next) !== true) return;

    await challenges.consume(email, 'password-reset', otp, null, async (client, challenge) => {
        const passwordHash = await bcrypt.hash(newPassword, 10);
        await client.query('UPDATE users SET password_hash = $1, email_session_version = $3 WHERE id = $2',
            [passwordHash, challenge.user_id, crypto.randomUUID()]);
        await client.query('UPDATE refresh_tokens SET revoked = TRUE WHERE user_id = $1 AND revoked = FALSE', [challenge.user_id]);
        return true;
    });
    res.json({ message: 'Password reset successful' });
});

exports.verifyEmail = catchAsync(async (req, res) => {
    const { email, otp, verificationId } = req.body;
    await challenges.consume(email, 'email-verification', otp, verificationId, async (client, challenge) => {
        const updated = await client.query(
            `UPDATE users SET is_email_verified = TRUE, email_session_version = $3
             WHERE id = $1 AND password_hash = $2 AND email = $4 AND is_email_verified IS FALSE`,
            [challenge.user_id, challenge.password_hash, verificationId, email]
        );
        if (!updated.rowCount) throw new AppError('Credentials have changed. Please sign in again.', 400);
        await client.query('UPDATE refresh_tokens SET revoked = TRUE WHERE user_id = $1 AND revoked = FALSE', [challenge.user_id]);
        return true;
    });
    res.json({ message: 'Email verified successfully!' });
});

exports.refreshToken = catchAsync(async (req, res, next) => {
    const { refreshToken, userId } = req.body;

    if (typeof refreshToken !== 'string' || !refreshToken || refreshToken.length > 512 ||
        !['number', 'string'].includes(typeof userId) || !/^[1-9]\d{0,9}$/.test(String(userId)) || Number(userId) > 2147483647) {
        return next(new AppError('Refresh token and user ID are required', 400));
    }

    const result = await db.query(
        `SELECT t.token_hash, u.email_session_version FROM refresh_tokens t JOIN users u ON u.id = t.user_id
         WHERE t.user_id = $1 AND u.is_email_verified IS NOT FALSE AND t.revoked = FALSE AND t.expires_at > NOW()`,
        [userId]
    );

    const grant = findMatchingToken(refreshToken, result.rows);
    if (!grant) {
        return next(new AppError('Invalid or expired refresh token', 401));
    }

    res.json({ token: generateToken(Number(userId), grant.email_session_version) });
});

exports.googleLogin = catchAsync(async (req, res, next) => {
    const { idToken } = req.body;

    if (!process.env.GOOGLE_CLIENT_ID) return next(new AppError('Google sign-in is unavailable.', 503));
    if (typeof idToken !== 'string' || !idToken) {
        return next(new AppError('Google ID Token is required', 400));
    }

    let ticket;
    try {
        ticket = await googleClient.verifyIdToken({ idToken, audience: process.env.GOOGLE_CLIENT_ID });
    } catch {
        return next(new AppError('Invalid Google sign-in token', 401));
    }

    const payload = ticket.getPayload();
    const { email, sub: googleId, name, picture } = payload;
    // Google is authoritative for Gmail and managed Workspace addresses.
    if (!googleId || typeof email !== 'string' || payload.email_verified !== true ||
        !(email.toLowerCase().endsWith('@gmail.com') || payload.hd)) {
        return next(new AppError('Use your ArborMed password to sign in with this email.', 401));
    }

    const result = await db.query(`SELECT ${USER_FIELDS}, email_session_version FROM users WHERE email = $1`, [email]);
    let user = result.rows[0];

    if (user) {
        if (user.is_email_verified === false) {
            return next(new AppError('Sign in with your password to verify this account, or reset your password.', 403));
        }
        const token = generateToken(user.id, user.email_session_version);
        const refreshToken = await generateRefreshToken(user.id);
        return res.json({ ...formatUserResponse(user), token, refreshToken, isNewUser: false });
    } else {
        return res.json({ email, googleId, suggestedDisplayName: name, photoUrl: picture, isNewUser: true });
    }
});

exports.logout = catchAsync(async (req, res) => {
    const { refreshToken } = req.body;
    const userId = req.user.id;

    if (refreshToken) {
        const result = await db.query(
            'SELECT id, token_hash FROM refresh_tokens WHERE user_id = $1 AND revoked = FALSE',
            [userId]
        );

        const matched = findMatchingToken(refreshToken, result.rows);
        if (matched) {
            await db.query('UPDATE refresh_tokens SET revoked = TRUE WHERE id = $1', [matched.id]);
        }
    }

    res.json({ message: 'Logged out successfully' });
});

exports.claimReward = (_req, _res, next) =>
    next(new AppError('Rewards are credited automatically when earned', 410));
