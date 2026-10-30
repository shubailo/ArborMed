const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');
const mailService = require('../services/mailService');
const { generateSecureOTP } = require('../utils/cryptoUtils');
const { validateEmail } = require('../utils/emailValidator');
const { auditLog } = require('./auditController');
const { OAuth2Client } = require('google-auth-library');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');
const { validatePassword, hashToken, findMatchingToken, formatUserResponse } = require('../utils/validators');
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// 🛡️ Sentinel: Pre-computed valid hash (cost 10) for timing attack mitigation
const DUMMY_HASH = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy';

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '15m', // Short-lived access token
    });
};

const generateRefreshToken = async (userId) => {
    const refreshToken = crypto.randomBytes(40).toString('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    await db.query(
        'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
        [userId, hashToken(refreshToken), expiresAt]
    );

    return refreshToken;
};

exports.register = catchAsync(async (req, res, next) => {
    const { email, password, username, display_name } = req.body;

    if (!email || !password) {
        return next(new AppError('Please provide email and password', 400));
    }

    if (validatePassword(password, next) !== true) return;

    // 📧 Validate Email Format & Domain
    const emailValidation = validateEmail(email);
    if (!emailValidation.isValid) {
        return next(new AppError(emailValidation.message, 400));
    }

    // 1. Check Main Users Table (Blocking)
    const userExists = await db.query(
        'SELECT * FROM users WHERE email = $1 OR username = $2',
        [email, username || '']
    );
    if (userExists.rows.length > 0) {
        const collision = userExists.rows[0].email === email ? 'Email' : 'Username';
        return next(
            new AppError(`${collision} already exists and is active.`, 400)
        );
    }

    // 2. Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Auto-generate username/display_name if missing
    const finalUsername = username || email.split('@')[0].toLowerCase();
    const finalDisplayName = display_name || email.split('@')[0];

    // 🚀 Instant Registration (No email verification required for test mode)
    const newUser = await db.query(
        'INSERT INTO users (email, password_hash, username, display_name, is_email_verified) VALUES ($1, $2, $3, $4, TRUE) RETURNING id, email, username, display_name, role, coins, xp, level, streak_count, longest_streak, is_email_verified',
        [email, hashedPassword, finalUsername, finalDisplayName]
    );

    const user = newUser.rows[0];
    const token = generateToken(user.id);
    const refreshToken = await generateRefreshToken(user.id);

    // Clean up any lingering pending_registrations for this email
    await db.query('DELETE FROM pending_registrations WHERE email = $1', [email]);

    res.status(201).json({
        message: 'Registration successful!',
        ...formatUserResponse(user),
        user: formatUserResponse(user),
        token,
        refreshToken,
    });
});

exports.resendRegistrationOTP = catchAsync(async (req, res, next) => {
    const { email } = req.body;

    if (!email) {
        return next(new AppError('Email is required', 400));
    }

    // 1. Check Pending Registrations
    const pendingCheck = await db.query(
        'SELECT * FROM pending_registrations WHERE email = $1',
        [email]
    );

    if (pendingCheck.rows.length === 0) {
        const alreadyRegistered = await db.query(
            'SELECT * FROM users WHERE email = $1',
            [email]
        );
        if (alreadyRegistered.rows.length > 0) {
            return res.status(200).json({
                message: 'Account is already verified! Please sign in with your password.',
            });
        }
        return next(
            new AppError('No pending registration found. Please register again.', 400)
        );
    }

    // 2. Generate New OTP
    const otp = generateSecureOTP(6);
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 mins

    // 3. Update DB
    await db.query(
        'UPDATE pending_registrations SET otp = $1, expires_at = $2 WHERE email = $3',
        [otp, expiresAt, email]
    );

    // 4. Resend Email in background
    mailService.sendOTP(email, otp).catch((err) => {
        console.warn(`[AUTH] Background mail resend notice for ${email}:`, err.message);
    });

    res.json({
        message: 'Verification code resent successfully.',
        otp: otp,
    });
});

exports.verifyRegistration = catchAsync(async (req, res, next) => {
    const { email, otp } = req.body;

    if (!email || !otp) {
        return next(new AppError('Please provide email and OTP', 400));
    }

    // 1. Check Pending Table
    const pendingCheck = await db.query(
        'SELECT * FROM pending_registrations WHERE email = $1 AND otp = $2 AND expires_at > NOW()',
        [email, otp]
    );

    if (pendingCheck.rows.length === 0) {
        const alreadyRegistered = await db.query(
            'SELECT * FROM users WHERE email = $1',
            [email]
        );
        if (alreadyRegistered.rows.length > 0) {
            const user = alreadyRegistered.rows[0];
            const token = generateToken(user.id);
            const refreshToken = await generateRefreshToken(user.id);
            return res.status(200).json({
                message: 'Registration successful! Welcome to ArborMed!',
                ...formatUserResponse(user),
                user: formatUserResponse(user),
                token,
                refreshToken,
            });
        }
        return next(new AppError('Invalid or expired OTP', 400));
    }

    const pendingUser = pendingCheck.rows[0];

    // 2. Move to Users Table (Finalize Registration)
    const newUser = await db.query(
        'INSERT INTO users (email, password_hash, username, display_name, is_email_verified) VALUES ($1, $2, $3, $4, TRUE) RETURNING id, email, username, role, coins, xp, level, is_email_verified',
        [
            pendingUser.email,
            pendingUser.password_hash,
            pendingUser.username,
            pendingUser.display_name,
        ]
    );

    const userId = newUser.rows[0].id;

    // 3. Generate Tokens
    const token = generateToken(userId);
    const refreshToken = await generateRefreshToken(userId);

    // 4. Cleanup Pending
    await db.query('DELETE FROM pending_registrations WHERE email = $1', [email]);

    res.status(201).json({
        message: 'Registration successful!',
        user: {
            id: userId,
            email: newUser.rows[0].email,
            username: newUser.rows[0].username,
            role: newUser.rows[0].role,
            is_email_verified: true,
        },
        token,
        refreshToken,
    });
});

exports.login = catchAsync(async (req, res, next) => {
    const { email, username, password } = req.body;
    const identifier = email || username;

    if (!identifier || !password) {
        return next(new AppError('Please provide credentials and password', 400));
    }

    let user;
    try {
        // Find by email OR username
        const result = await db.query(
            'SELECT * FROM users WHERE email = $1 OR username = $1',
            [identifier]
        );
        user = result.rows[0];
    } catch (dbErr) {
        // 🧪 Development Offline Fallback: If DB is unreachable (e.g. Supabase paused), allow dev test login
        if (process.env.NODE_ENV === 'development') {
            console.warn(`[AUTH] DB unreachable (${dbErr.message}). Starting development test session.`);
            const devUser = {
                id: 1,
                email: identifier.includes('@') ? identifier : `${identifier}@arbormed.test`,
                username: identifier.includes('@') ? identifier.split('@')[0] : identifier,
                display_name: 'Dr. ArborMed (Dev)',
                role: 'student',
                coins: 500,
                xp: 1250,
                level: 3,
                streak_count: 5,
                longest_streak: 12,
                is_email_verified: true,
            };
            const token = generateToken(devUser.id);
            const refreshToken = 'dev_refresh_token_' + Date.now();
            return res.json({
                ...formatUserResponse(devUser),
                token,
                refreshToken
            });
        }
        throw dbErr;
    }

    // 🛡️ Sentinel: Mitigate timing attacks by always performing a comparison
    const validUser = !!user;
    const hashToCompare = validUser ? user.password_hash : DUMMY_HASH;

    // Always run compare to ensure consistent timing
    const isMatch = await bcrypt.compare(password, hashToCompare);

    if (validUser && isMatch) {
        const token = generateToken(user.id);
        const refreshToken = await generateRefreshToken(user.id);

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
    let row;
    try {
        const result = await db.query(
            'SELECT id, email, username, display_name, role, coins, xp, level, streak_count, longest_streak, is_email_verified FROM users WHERE id = $1',
            [req.user.id]
        );
        row = result.rows[0];
    } catch (dbErr) {
        if (process.env.NODE_ENV === 'development') {
            return res.json({
                id: req.user.id || 1,
                email: 'dev@arbormed.test',
                username: 'dev_student',
                display_name: 'Dr. ArborMed (Dev)',
                role: 'student',
                coins: 500,
                xp: 1250,
                level: 3,
                streak_count: 5,
                longest_streak: 12,
                is_email_verified: true,
            });
        }
        throw dbErr;
    }

    if (!row) {
        return next(new AppError('User not found', 404));
    }

    res.json(formatUserResponse(row));
});

exports.changePassword = catchAsync(async (req, res, next) => {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
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
        return next(new AppError('Incorrect current password', 401));
    }

    const salt = await bcrypt.genSalt(10);
    const hashedNewPassword = await bcrypt.hash(newPassword, salt);

    await db.query('UPDATE users SET password_hash = $1 WHERE id = $2', [
        hashedNewPassword,
        req.user.id,
    ]);

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
    const { email } = req.body;

    if (!email) {
        return next(new AppError('Please provide an email address', 400));
    }

    // 1. Check if user exists (Silent fail to prevent enumeration)
    const userCheck = await db.query('SELECT id FROM users WHERE email = $1', [
        email,
    ]);
    if (userCheck.rows.length === 0) {
        console.warn(`[OTP] Request for non-existent email: ${email}`);
        return res.json({
            message: 'If this email is registered, a code has been sent.',
        });
    }

    const otp = generateSecureOTP(6);
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

    // 🛡️ Sentinel: Respond immediately, process email in background
    res.json({
        message: 'If this email is registered, a code has been sent.',
        otp: otp,
    });

    (async () => {
        try {
            await db.query('DELETE FROM password_resets WHERE email = $1', [email]);
            await db.query(
                'INSERT INTO password_resets (email, otp, expires_at) VALUES ($1, $2, $3)',
                [email, otp, expiresAt]
            );
            await mailService.sendOTP(email, otp);
        } catch (error) {
            console.error(`[OTP] Background processing error for ${email}:`, error);
        }
    })();
});

exports.resetPassword = catchAsync(async (req, res, next) => {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
        return next(
            new AppError('Please provide email, OTP, and new password', 400)
        );
    }

    if (validatePassword(newPassword, next) !== true) return;

    const otpCheck = await db.query(
        'SELECT * FROM password_resets WHERE email = $1 AND otp = $2 AND expires_at > NOW()',
        [email, otp]
    );

    if (otpCheck.rows.length === 0) {
        return next(new AppError('Invalid or expired OTP', 400));
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(newPassword, salt);

    await db.query('UPDATE users SET password_hash = $1 WHERE email = $2', [
        password_hash,
        email,
    ]);
    await db.query('DELETE FROM password_resets WHERE email = $1', [email]);

    res.json({ message: 'Password reset successful' });
});

exports.verifyEmail = catchAsync(async (req, res, next) => {
    const { email, otp } = req.body;

    if (!email || !otp) {
        return next(new AppError('Please provide email and OTP', 400));
    }

    const otpCheck = await db.query(
        'SELECT * FROM password_resets WHERE email = $1 AND otp = $2 AND expires_at > NOW()',
        [email, otp]
    );

    if (otpCheck.rows.length === 0) {
        return next(new AppError('Invalid or expired OTP', 400));
    }

    await db.query('UPDATE users SET is_email_verified = TRUE WHERE email = $1', [
        email,
    ]);
    await db.query('DELETE FROM password_resets WHERE email = $1', [email]);

    res.json({ message: 'Email verified successfully!' });
});

exports.refreshToken = catchAsync(async (req, res, next) => {
    const { refreshToken, userId } = req.body;

    if (!refreshToken || !userId) {
        return next(new AppError('Refresh token and user ID are required', 400));
    }

    const result = await db.query(
        'SELECT * FROM refresh_tokens WHERE user_id = $1 AND revoked = FALSE AND expires_at > NOW()',
        [userId]
    );

    if (!findMatchingToken(refreshToken, result.rows)) {
        return next(new AppError('Invalid or expired refresh token', 401));
    }

    res.json({ token: generateToken(userId) });
});

exports.googleLogin = catchAsync(async (req, res, next) => {
    const { idToken } = req.body;

    if (!idToken) {
        return next(new AppError('Google ID Token is required', 400));
    }

    const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    const { email, sub: googleId, name, picture } = payload;

    let result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    let user = result.rows[0];

    if (user) {
        const token = generateToken(user.id);
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

exports.claimReward = catchAsync(async (req, res, next) => {
    const { amount } = req.body;
    const userId = req.user.id;

    const rewardAmount = parseInt(amount, 10);
    if (isNaN(rewardAmount) || rewardAmount <= 0) {
        return next(new AppError('Valid positive reward amount is required', 400));
    }

    // Maximum cap per single claim to prevent client tampering
    if (rewardAmount > 1000) {
        return next(new AppError('Reward amount exceeds maximum allowed single claim limit', 400));
    }

    const result = await db.query(
        'UPDATE users SET coins = coins + $1 WHERE id = $2 RETURNING id, coins, xp',
        [rewardAmount, userId]
    );

    if (result.rows.length === 0) {
        return next(new AppError('User not found', 404));
    }

    res.json({
        message: 'Reward claimed successfully',
        coins: result.rows[0].coins,
        xp: result.rows[0].xp,
    });
});
