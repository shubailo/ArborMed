const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const db = require('./src/config/db');

const http = require('http');
const { initializeSocket } = require('./src/services/socketService');

const app = express();
app.set('trust proxy', 1); // Trust the first proxy (Render/Heroku/etc)
const server = http.createServer(app); // Create HTTP Server
initializeSocket(server); // Attach Socket.io

const path = require('path');
const rateLimit = require('express-rate-limit');

// Rate Limiting
const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 1000, // Limit each IP to 1000 requests per window
    message: 'Too many requests from this IP, please try again after 15 minutes'
});

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 50, // Stricter limit for login/register/otp
    message: 'Too many authentication attempts, please try again after 15 minutes'
});

// Middleware
app.use(globalLimiter);
app.use(helmet());

const allowedOriginsArray = process.env.ALLOWED_ORIGINS
    ? process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
    : [];

// Add default production origins if not present
const defaultOrigins = [
    'https://arbor-med.netlify.app',
    'https://master--arbor-med.netlify.app'
];

app.use(cors({
    origin: (origin, callback) => {
        // 1. Always allow if no origin (e.g. server-to-server, mobile app) or development mode
        if (!origin || process.env.NODE_ENV === 'development') {
            return callback(null, true);
        }

        // 2. check if explicitly in ALLOWED_ORIGINS env
        if (allowedOriginsArray.includes(origin)) {
            return callback(null, true);
        }

        // 3. check default ArborMed origins
        if (defaultOrigins.includes(origin)) {
            return callback(null, true);
        }

        // 4. check if it's a Netlify subdomain (support branch previews)
        if (origin.endsWith('.netlify.app')) {
            return callback(null, true);
        }

        console.warn(`[CORS] Blocked request from unauthorized origin: ${origin}`);
        callback(new Error('Not allowed by CORS'));
    },
    credentials: true
}));
app.use(morgan('dev'));
app.use(express.json());

const authRoutes = require('./src/routes/authRoutes');
const quizRoutes = require('./src/routes/quizRoutes');
const shopRoutes = require('./src/routes/shopRoutes');
const statsRoutes = require('./src/routes/statsRoutes');
const socialRoutes = require('./src/routes/socialRoutes');
const translateRoutes = require('./src/routes/translate');
const uploadRoutes = require('./src/routes/uploadRoutes');
const ecgRoutes = require('./src/routes/ecgRoutes');
const adminRoutes = require('./src/routes/adminRoutes');
const notificationRoutes = require('./src/routes/notificationRoutes');
const reportRoutes = require('./src/routes/reportRoutes');
const questRoutes = require('./src/routes/questRoutes');
const crateRoutes = require('./src/routes/crateRoutes');

// Routes
app.use('/auth', authLimiter, authRoutes);
app.use('/quiz', quizRoutes);
app.use('/ecg', ecgRoutes);
app.use('/shop', shopRoutes);
app.use('/stats', statsRoutes);
app.use('/social', socialRoutes);
app.use('/admin', adminRoutes);
app.use('/quests', questRoutes);
app.use('/crates', crateRoutes);
app.use('/notifications', notificationRoutes);
app.use('/reports', reportRoutes);
app.use('/api', authLimiter, translateRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.get('/', (req, res) => {
    res.json({ message: 'AGOOM API is running', version: '1.0.0' });
});

app.get('/health', async (req, res) => {
    try {
        const result = await db.query('SELECT NOW()');
        res.json({ status: 'ok', db_time: result.rows[0].now, message: 'AGOOM API is running' });
    } catch (err) {
        console.error('[Health Check Error]:', err);
        res.status(500).json({ 
            status: 'error', 
            message: 'Database connection failed',
            details: process.env.NODE_ENV === 'development' ? err.message : 'Check server logs for details'
        });
    }
});

const errorHandler = require('./src/middleware/errorHandler');

// Centralized error handler (must be AFTER all routes)
app.use(errorHandler);

const PORT = process.env.PORT || 3000;

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});

