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

const path = require('path');
const rateLimit = require('express-rate-limit');

// Rate Limiting
const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 1000, // Limit each IP to 1000 requests per window
    message: 'Too many requests from this IP, please try again after 15 minutes'
});

// Middleware
app.use(helmet());

const { corsOrigin } = require('./src/config/origins');
app.use(cors({ origin: corsOrigin, credentials: true }));
morgan.token('route-path', req => req.originalUrl.split('?')[0]);
app.use(morgan(':method :route-path :status :response-time ms'));
app.use(globalLimiter);
app.use(express.json());

const authRoutes = require('./src/routes/authRoutes');
const quizRoutes = require('./src/routes/quizRoutes');
const shopRoutes = require('./src/routes/shopRoutes');
const statsRoutes = require('./src/routes/statsRoutes');
const gamificationRoutes = require('./src/routes/gamificationRoutes');
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
app.use('/auth', authRoutes);
app.use('/quiz', quizRoutes);
app.use('/ecg', ecgRoutes);
app.use('/shop', shopRoutes);
app.use('/stats', statsRoutes);
app.use('/gamification', gamificationRoutes);
app.use('/social', socialRoutes);
app.use('/admin', adminRoutes);
app.use('/quests', questRoutes);
app.use('/crates', crateRoutes);
app.use('/notifications', notificationRoutes);
app.use('/reports', reportRoutes);
app.use('/api', translateRoutes);
app.use('/api/upload', uploadRoutes);
// Uploaded learning images are embedded by the separately hosted student app.
app.use('/uploads', helmet.crossOriginResourcePolicy({ policy: 'cross-origin' }));
app.get('/uploads/stored/:group/:filename', (req, res) => {
    const url = require('./src/services/uploadStorage').publicUrl(req.params.group, req.params.filename);
    if (!url) return res.sendStatus(404);
    res.redirect(302, url);
});
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.get('/', (req, res) => {
    res.json({ message: 'ArborMed API is running', version: '1.0.0' });
});

app.get('/ping', (req, res) => {
    res.json({ status: 'ok', timestamp: Date.now() });
});

const { releaseMigrations, readMigrationStatus } = require('./src/scripts/migrate');
const manifest = releaseMigrations();
let lastReadinessFailure;

function logReadinessFailure(details) {
    const message = JSON.stringify(details);
    if (message === lastReadinessFailure) return;
    lastReadinessFailure = message;
    console.warn('[Health Check Warning]', message);
}

app.get('/health', async (req, res) => {
    try {
        const schema = await readMigrationStatus(db, manifest);
        if (!schema.ready) {
            logReadinessFailure({ missing: schema.missing, changed: schema.changed });
            return res.status(503).json({ status: 'degraded', message: 'Database migration state does not match the release' });
        }
        lastReadinessFailure = undefined;
        res.json({ status: 'ok', db_time: schema.now, message: 'ArborMed API is running' });
    } catch (err) {
        const code = /^[A-Z0-9_]{2,32}$/.test(err?.code) ? err.code : 'unclassified';
        logReadinessFailure({ code });
        res.status(503).json({ status: 'degraded', message: 'Database unavailable' });
    }
});

const errorHandler = require('./src/middleware/errorHandler');

// Centralized error handler (must be AFTER all routes)
app.use(errorHandler);

function startServer(port = process.env.PORT || 3000) {
    const server = http.createServer(app);
    initializeSocket(server);
    return server.listen(port, '0.0.0.0', () => console.log('Server listening on port', port));
}

if (require.main === module) startServer();
module.exports = { app, startServer };
