const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');
const mailService = require('../services/mailService');
const randomstring = require('randomstring');
const { validateEmail } = require('../utils/emailValidator');
const { auditLog } = require('./auditController');
const { OAuth2Client } = require('google-auth-library');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);


const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '15m', // Short-lived access token
    });
};

const generateRefreshToken = async (userId) => {
    const refreshToken = crypto.randomBytes(40).toString('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');

    await db.query(
        'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
        [userId, tokenHash, expiresAt]
    );

    return refreshToken;
};

exports.register = catchAsync(async (req, res, next) => {
    const { email, password, username, display_name } = req.body;

    if (!email || !password) {
        return next(new AppError('Please provide email and password', 400));
    }


    // 🔒 Strict Password Policy: Min 8 chars, 1 Upper, 1 Lower, 1 Number, 1 Special Char
    // Revised to allow ANY special character while maintaining the "at least one" requirement
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W\_]).{8,}$/;
    if (!passwordRegex.test(password)) {
        return next(new AppError('Password must be at least 8 characters long and include an uppercase letter, a number, and a special character.', 400));
    }


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
        return next(new AppError(`${collision} already exists and is active.`, 400));
    }


    // 2. Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Auto-generate username/display_name if missing
    const finalUsername = username || email.split('@')[0].toLowerCase();
    const finalDisplayName = display_name || email.split('@')[0];

    // 3. Generate OTP
    const otp = randomstring.generate({ length: 6, charset: 'numeric' });
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 mins

    // 4. Update Pending Registrations (Upsert-ish)
    // Check if pending exists
    const pendingCheck = await db.query('SELECT * FROM pending_registrations WHERE email = $1', [email]);

    if (pendingCheck.rows.length > 0) {
        // Update existing pending
        await db.query(
            'UPDATE pending_registrations SET username = $1, password_hash = $2, display_name = $3, otp = $4, expires_at = $5 WHERE email = $6',
            [finalUsername, hashedPassword, finalDisplayName, otp, expiresAt, email]
        );
    } else {
        // Insert new pending
        await db.query(
            'INSERT INTO pending_registrations (email, username, password_hash, display_name, otp, expires_at) VALUES ($1, $2, $3, $4, $5, $6)',
            [email, finalUsername, hashedPassword, finalDisplayName, otp, expiresAt]
        );
    }

    // 5. Send OTP
    await mailService.sendOTP(email, otp);

    res.status(200).json({
        message: 'Verification code sent. Please check your email.',
        email: email // Send back for frontend reference
    });
});

exports.resendRegistrationOTP = catchAsync(async (req, res, next) => {
    const { email } = req.body;

    if (!email) {
        return next(new AppError('Email is required', 400));
    }

    // 1. Check Pending Registrations
    const pendingCheck = await db.query('SELECT * FROM pending_registrations WHERE email = $1', [email]);

    if (pendingCheck.rows.length === 0) {
        return next(new AppError('No pending registration found. Please register again.', 400));
    }

    // 2. Generate New OTP
    const otp = randomstring.generate({ length: 6, charset: 'numeric' });
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 mins

    // 3. Update DB
    await db.query(
        'UPDATE pending_registrations SET otp = $1, expires_at = $2 WHERE email = $3',
        [otp, expiresAt, email]
    );

    // 4. Resend Email
    await mailService.sendOTP(email, otp);

    res.json({ message: 'Verification code resent successfully.' });
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
        return next(new AppError('Invalid or expired OTP', 400));
    }

    const pendingUser = pendingCheck.rows[0];

    // 2. Move to Users Table (Finalize Registration)
    const newUser = await db.query(
        'INSERT INTO users (email, password_hash, username, display_name, is_email_verified) VALUES ($1, $2, $3, $4, TRUE) RETURNING id, email, username, role, coins, xp, level, is_email_verified',
        [pendingUser.email, pendingUser.password_hash, pendingUser.username, pendingUser.display_name]
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

    // Find by email OR username
    const result = await db.query(
        'SELECT * FROM users WHERE email = $1 OR username = $1',
        [identifier]
    );
    const user = result.rows[0];

    if (user && (await bcrypt.compare(password, user.password_hash))) {

        const token = generateToken(user.id);
        const refreshToken = await generateRefreshToken(user.id);

        res.json({
            id: user.id,
            email: user.email,
            username: user.username,
            display_name: user.display_name,
            role: user.role,
            coins: user.coins,
            xp: user.xp,
            level: user.level,
            streak_count: user.streak_count,
            longest_streak: user.longest_streak,
            is_email_verified: user.is_email_verified,
            token,
            refreshToken,
        });

        // 🛡️ Audit Log: Successful Login
        await auditLog({
            userId: user.id,
            actionType: 'LOGIN_SUCCESS',
            severity: 'INFO',
            metadata: { identifier, timestamp: new Date() }
        });
    } else {
        // 🛡️ Audit Log: Failed Login Attempt
        await auditLog({
            actionType: 'LOGIN_FAILURE',
            severity: 'WARNING',
            metadata: { identifier, timestamp: new Date() }
        });
        return next(new AppError('Invalid credentials', 401));
    }
});


exports.getMe = catchAsync(async (req, res, next) => {
    const result = await db.query(
        'SELECT id, email, username, display_name, role, coins, xp, level, streak_count, longest_streak, is_email_verified FROM users WHERE id = $1',
        [req.user.id]
    );

    if (result.rows.length === 0) {
        return next(new AppError('User not found', 404));
    }

    const user = result.rows[0];
    res.json({
        id: user.id,
        email: user.email,
        username: user.username,
        display_name: user.display_name,
        role: user.role,
        coins: user.coins,
        xp: user.xp,
        level: user.level,
        streak_count: user.streak_count,
        longest_streak: user.longest_streak,
        is_email_verified: user.is_email_verified
    });
});


exports.changePassword = catchAsync(async (req, res, next) => {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
        return next(new AppError('Please provide both current and new passwords', 400));
    }

    // 🔒 Strict Password Policy
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W\_]).{8,}$/;
    if (!passwordRegex.test(newPassword)) {
        return next(new AppError('New password must be at least 8 characters long and include an uppercase letter, a number, and a special character.', 400));
    }

    const result = await db.query('SELECT password_hash FROM users WHERE id = $1', [req.user.id]);
    const user = result.rows[0];

    if (!user || !(await bcrypt.compare(currentPassword, user.password_hash))) {
        return next(new AppError('Incorrect current password', 401));
    }

    const salt = await bcrypt.genSalt(10);
    const hashedNewPassword = await bcrypt.hash(newPassword, salt);

    await db.query('UPDATE users SET password_hash = $1 WHERE id = $2', [hashedNewPassword, req.user.id]);

    // 🛡️ Audit Log: Password Change
    await auditLog({
        userId: req.user.id,
        actionType: 'PASSWORD_CHANGE',
        severity: 'PROTECTED',
        metadata: { timestamp: new Date() }
    });

    res.json({ message: 'Password updated successfully' });
});


exports.updateProfile = catchAsync(async (req, res, next) => {
    const { username, display_name } = req.body;

    // Check if username is taken if changing it
    if (username) {
        const check = await db.query('SELECT id FROM users WHERE username = $1 AND id != $2', [username, req.user.id]);
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
    const userCheck = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    if (userCheck.rows.length === 0) {
        console.warn(`[OTP] Request for non-existent email: ${email}`);
        return res.json({ message: 'If this email is registered, a code has been sent.' });
    }

    const otp = randomstring.generate({ length: 6, charset: 'numeric' });
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

    await db.query('DELETE FROM password_resets WHERE email = $1', [email]);
    await db.query(
        'INSERT INTO password_resets (email, otp, expires_at) VALUES ($1, $2, $3)',
        [email, otp, expiresAt]
    );

    await mailService.sendOTP(email, otp);
    res.json({ message: 'If this email is registered, a code has been sent.' });
});


exports.resetPassword = catchAsync(async (req, res, next) => {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
        return next(new AppError('Please provide email, OTP, and new password', 400));
    }

    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W\_]).{8,}$/;
    if (!passwordRegex.test(newPassword)) {
        return next(new AppError('New password must be at least 8 characters long and include an uppercase letter, a number, and a special character.', 400));
    }

    const otpCheck = await db.query(
        'SELECT * FROM password_resets WHERE email = $1 AND otp = $2 AND expires_at > NOW()',
        [email, otp]
    );

    if (otpCheck.rows.length === 0) {
        return next(new AppError('Invalid or expired OTP', 400));
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(newPassword, salt);

    await db.query('UPDATE users SET password_hash = $1 WHERE email = $2', [password_hash, email]);
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

    await db.query('UPDATE users SET is_email_verified = TRUE WHERE email = $1', [email]);
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

    const tokens = result.rows;
    let validToken = null;
    const hashedInput = crypto.createHash('sha256').update(refreshToken).digest('hex');

    for (const t of tokens) {
        if (hashedInput === t.token_hash) {
            validToken = t;
            break;
        }
    }

    if (!validToken) {
        return next(new AppError('Invalid or expired refresh token', 401));
    }

    const newToken = generateToken(userId);
    res.json({ token: newToken });
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

        return res.json({
            id: user.id,
            email: user.email,
            username: user.username,
            display_name: user.display_name,
            role: user.role,
            coins: user.coins,
            xp: user.xp,
            level: user.level,
            is_email_verified: user.is_email_verified,
            token,
            refreshToken,
            isNewUser: false
        });
    } else {
        return res.status(200).json({
            email,
            googleId,
            suggestedDisplayName: name,
            photoUrl: picture,
            isNewUser: true
        });
    }
});


exports.logout = catchAsync(async (req, res, next) => {
    const { refreshToken } = req.body;
    const userId = req.user.id;

    if (refreshToken) {
        const result = await db.query(
            'SELECT id, token_hash FROM refresh_tokens WHERE user_id = $1 AND revoked = FALSE',
            [userId]
        );

        const hashedInput = crypto.createHash('sha256').update(refreshToken).digest('hex');

        for (const t of result.rows) {
            if (hashedInput === t.token_hash) {
                await db.query('UPDATE refresh_tokens SET revoked = TRUE WHERE id = $1', [t.id]);
                break;
            }
        }
    }

    res.json({ message: 'Logged out successfully' });
});

