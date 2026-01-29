const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '30d',
    });
};

exports.register = async (req, res) => {
    const { name, email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Please provide email and password' });
    }

    try {
        // Check if user exists
        const userExists = await db.query('SELECT * FROM users WHERE email = $1', [email]);
        if (userExists.rows.length > 0) {
            return res.status(400).json({ message: 'User already exists' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Create user
        // Note: 'name' is not in the original schema but 'email' is. 
        // The schema has 'email', 'password_hash', 'role', 'coins', 'xp', 'level'.
        // We will stick to the schema or simple email/password for now.

        // Attempting to insert
        const newUser = await db.query(
            'INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id, email, role, coins, xp, level',
            [email, hashedPassword]
        );

        res.status(201).json({
            id: newUser.rows[0].id,
            email: newUser.rows[0].email,
            role: newUser.rows[0].role,
            token: generateToken(newUser.rows[0].id),
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.login = async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Please provide email and password' });
    }

    try {
        const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
        const user = result.rows[0];

        if (user && (await bcrypt.compare(password, user.password_hash))) {
            res.json({
                id: user.id,
                email: user.email,
                role: user.role,
                coins: user.coins,
                xp: user.xp,
                level: user.level,
                token: generateToken(user.id),
            });
        } else {
            res.status(401).json({ message: 'Invalid credentials' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.getMe = async (req, res) => {
    try {
        // req.user is set by authMiddleware
        const result = await db.query('SELECT id, email, role, coins, xp, level, streak_count FROM users WHERE id = $1', [req.user.id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        const user = result.rows[0];
        res.json({
            id: user.id,
            email: user.email,
            role: user.role,
            coins: user.coins,
            xp: user.xp,
            level: user.level,
            streak_count: user.streak_count
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};
