const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const mailService = require('../services/mailService');
const randomstring = require('randomstring');
const { validateEmail } = require('../utils/emailValidator');

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '15m', // Short-lived access token
    });
};

const generateRefreshToken = async (userId) => {
    const refreshToken = require('crypto').randomBytes(40).toString('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    // Hash the token before storing
    const salt = await bcrypt.genSalt(10);
    const tokenHash = await bcrypt.hash(refreshToken, salt);

    await db.query(
        'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
        [userId, tokenHash, expiresAt]
    );

    return refreshToken;
};

exports.register = async (req, res) => {
    const { email, password, username, display_name } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Please provide email and password' });
    }

    // 📧 Validate Email Format & Domain
    const emailValidation = validateEmail(email);
    if (!emailValidation.isValid) {
        return res.status(400).json({ message: emailValidation.message });
    }

    try {
        // 1. Check Main Users Table (Blocking)
        const userExists = await db.query(
            'SELECT * FROM users WHERE email = $1 OR username = $2',
            [email, username || '']
        );
        if (userExists.rows.length > 0) {
            const collision = userExists.rows[0].email === email ? 'Email' : 'Username';
            return res.status(400).json({ message: `${collision} already exists and is active.` });
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

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error during registration' });
    }
};

exports.verifyRegistration = async (req, res) => {
    const { email, otp } = req.body;

    if (!email || !otp) {
        return res.status(400).json({ message: 'Please provide email and OTP' });
    }

    try {
        // 1. Check Pending Table
        const pendingCheck = await db.query(
            'SELECT * FROM pending_registrations WHERE email = $1 AND otp = $2 AND expires_at > NOW()',
            [email, otp]
        );

        if (pendingCheck.rows.length === 0) {
            return res.status(400).json({ message: 'Invalid or expired OTP' });
        }

        const pendingUser = pendingCheck.rows[0];

        // 2. Move to Users Table (Finalize Registration)
        // Note: is_email_verified = TRUE by definition effectively
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

    } catch (error) {
        console.error('❌ Verify Registration Error:', error);
        res.status(500).json({ message: 'Failed to verify registration' });
    }
};

exports.login = async (req, res) => {
    const { email, username, password } = req.body;
    const identifier = email || username;

    if (!identifier || !password) {
        return res.status(400).json({ message: 'Please provide credentials and password' });
    }

    try {
        // Find by email OR username
        const result = await db.query(
            'SELECT * FROM users WHERE email = $1 OR username = $1',
            [identifier]
        );
        const user = result.rows[0];

        if (user && (await bcrypt.compare(password, user.password_hash))) {
            // 📧 Check Verification Status
            if (user.is_email_verified === false) {
                return res.status(403).json({
                    message: 'Please verify your email address to continue.',
                    code: 'EMAIL_NOT_VERIFIED',
                    email: user.email,
                    id: user.id
                });
            }

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
                is_email_verified: user.is_email_verified, // Fix: Return verification status
                token,
                refreshToken,
            });
        } else {
            res.status(401).json({ message: 'Invalid credentials' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error during login' });
    }
};

exports.getMe = async (req, res) => {
    try {
        const result = await db.query(
            'SELECT id, email, username, display_name, role, coins, xp, level, streak_count, longest_streak, is_email_verified FROM users WHERE id = $1',
            [req.user.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'User not found' });
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
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error fetching profile' });
    }
};

exports.changePassword = async (req, res) => {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
        return res.status(400).json({ message: 'Please provide both current and new passwords' });
    }

    try {
        const result = await db.query('SELECT password_hash FROM users WHERE id = $1', [req.user.id]);
        const user = result.rows[0];

        if (!user || !(await bcrypt.compare(currentPassword, user.password_hash))) {
            return res.status(401).json({ message: 'Incorrect current password' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedNewPassword = await bcrypt.hash(newPassword, salt);

        await db.query('UPDATE users SET password_hash = $1 WHERE id = $2', [hashedNewPassword, req.user.id]);

        res.json({ message: 'Password updated successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error updating password' });
    }
};

exports.updateProfile = async (req, res) => {
    const { username, display_name } = req.body;

    try {
        // Check if username is taken if changing it
        if (username) {
            const check = await db.query('SELECT id FROM users WHERE username = $1 AND id != $2', [username, req.user.id]);
            if (check.rows.length > 0) {
                return res.status(400).json({ message: 'Username is already taken' });
            }
        }

        const result = await db.query(
            'UPDATE users SET username = COALESCE($1, username), display_name = COALESCE($2, display_name) WHERE id = $3 RETURNING username, display_name',
            [username, display_name, req.user.id]
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error updating profile' });
    }
};

exports.requestOTP = async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'Please provide an email address' });
    }

    try {
        // 1. Check if user exists
        const userCheck = await db.query('SELECT id FROM users WHERE email = $1', [email]);
        if (userCheck.rows.length === 0) {
            return res.status(404).json({ message: 'No user found with this email' });
        }

        // 2. Generate 6-digit OTP
        const otp = randomstring.generate({
            length: 6,
            charset: 'numeric'
        });

        // 3. Store OTP in database (valid for 10 minutes)
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins from now

        // Delete any existing OTPs for this email first
        await db.query('DELETE FROM password_resets WHERE email = $1', [email]);

        await db.query(
            'INSERT INTO password_resets (email, otp, expires_at) VALUES ($1, $2, $3)',
            [email, otp, expiresAt]
        );

        // 4. Send OTP via email
        await mailService.sendOTP(email, otp);

        res.json({ message: 'OTP sent successfully' });
    } catch (error) {
        console.error('Request OTP Error:', error);
        res.status(500).json({ message: 'Failed to request OTP' });
    }
};

exports.resetPassword = async (req, res) => {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
        return res.status(400).json({ message: 'Please provide email, OTP, and new password' });
    }

    try {
        // 1. Verify OTP
        const otpCheck = await db.query(
            'SELECT * FROM password_resets WHERE email = $1 AND otp = $2 AND expires_at > NOW()',
            [email, otp]
        );

        if (otpCheck.rows.length === 0) {
            return res.status(400).json({ message: 'Invalid or expired OTP' });
        }

        // 2. Hash new password
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(newPassword, salt);

        // 3. Update user password
        await db.query('UPDATE users SET password_hash = $1 WHERE email = $2', [password_hash, email]);

        // 4. Delete used OTP
        await db.query('DELETE FROM password_resets WHERE email = $1', [email]);

        res.json({ message: 'Password reset successful' });
    } catch (error) {
        console.error('Reset Password Error:', error);
        res.status(500).json({ message: 'Failed to reset password' });
    }
};

exports.verifyEmail = async (req, res) => {
    const { email, otp } = req.body;

    if (!email || !otp) {
        return res.status(400).json({ message: 'Please provide email and OTP' });
    }

    try {
        const otpCheck = await db.query(
            'SELECT * FROM password_resets WHERE email = $1 AND otp = $2 AND expires_at > NOW()',
            [email, otp]
        );

        if (otpCheck.rows.length === 0) {
            return res.status(400).json({ message: 'Invalid or expired OTP' });
        }

        // 1. Mark user as verified
        await db.query('UPDATE users SET is_email_verified = TRUE WHERE email = $1', [email]);

        // 2. Cleanup OTP
        await db.query('DELETE FROM password_resets WHERE email = $1', [email]);

        res.json({ message: 'Email verified successfully!' });
    } catch (error) {
        console.error('❌ Verify Email Error:', {
            message: error.message,
            stack: error.stack,
            email
        });
        res.status(500).json({
            message: 'Failed to verify email',
            error: error.message
        });
    }
};

exports.refreshToken = async (req, res) => {
    const { refreshToken, userId } = req.body;

    if (!refreshToken || !userId) {
        return res.status(400).json({ message: 'Refresh token and user ID are required' });
    }

    try {
        // Find all non-revoked, non-expired tokens for this user
        const result = await db.query(
            'SELECT * FROM refresh_tokens WHERE user_id = $1 AND revoked = FALSE AND expires_at > NOW()',
            [userId]
        );

        const tokens = result.rows;
        let validToken = null;

        for (const t of tokens) {
            if (await bcrypt.compare(refreshToken, t.token_hash)) {
                validToken = t;
                break;
            }
        }

        if (!validToken) {
            return res.status(401).json({ message: 'Invalid or expired refresh token' });
        }

        // Generate new access token
        const newToken = generateToken(userId);

        res.json({ token: newToken });
    } catch (error) {
        console.error('Refresh Token Error:', error);
        res.status(500).json({ message: 'Server error during token refresh' });
    }
};

const { OAuth2Client } = require('google-auth-library');
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

exports.googleLogin = async (req, res) => {
    const { idToken } = req.body;

    if (!idToken) {
        return res.status(400).json({ message: 'Google ID Token is required' });
    }

    try {
        console.log('🔍 Google Login Attempt with token length:', idToken?.length);
        // 1. Verify Google Token
        const ticket = await googleClient.verifyIdToken({
            idToken,
            audience: process.env.GOOGLE_CLIENT_ID,
        });

        const payload = ticket.getPayload();
        console.log('✅ Google Token Verified. Payload:', {
            email: payload.email,
            name: payload.name,
            aud: payload.aud
        });
        const { email, sub: googleId, name, picture } = payload;

        // 2. Check if user already exists (by email OR google_id if we had one)
        // We'll use email as the primary bridge.
        let result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
        let user = result.rows[0];

        if (user) {
            // Existing user - Login directly
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
                is_email_verified: user.is_email_verified, // Fix: Include verification status for Google Logins too
                token,
                refreshToken,
                isNewUser: false
            });
        } else {
            // New user - We need them to "Complete Profile" (pick a username)
            // Send back the verified info so the app can pre-fill
            return res.status(200).json({
                email,
                googleId,
                suggestedDisplayName: name,
                photoUrl: picture,
                isNewUser: true
            });
        }
    } catch (error) {
        console.error('Google Auth Error:', error);
        res.status(401).json({ message: 'Invalid Google Token' });
    }
};

exports.logout = async (req, res) => {
    const { refreshToken } = req.body;
    const userId = req.user.id;

    try {
        if (refreshToken) {
            // Revoke specific refresh token
            const result = await db.query(
                'SELECT id, token_hash FROM refresh_tokens WHERE user_id = $1 AND revoked = FALSE',
                [userId]
            );

            for (const t of result.rows) {
                if (await bcrypt.compare(refreshToken, t.token_hash)) {
                    await db.query('UPDATE refresh_tokens SET revoked = TRUE WHERE id = $1', [t.id]);
                    break;
                }
            }
        }

        res.json({ message: 'Logged out successfully' });
    } catch (error) {
        console.error('Logout Error:', error);
        res.status(500).json({ message: 'Server error during logout' });
    }
};
