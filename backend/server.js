const express = require('express');
// const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const db = require('./src/config/db');

const http = require('http'); // Import HTTP
const { initializeSocket } = require('./src/services/socketService'); // Import Socket Service

const app = express();
const server = http.createServer(app); // Create HTTP Server
initializeSocket(server); // Attach Socket.io

// Middleware
// app.use(helmet()); 
app.use(cors()); // Allow all origins for Dev
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
const adminRoutes = require('./src/routes/adminRoutes'); // New
const notificationRoutes = require('./src/routes/notificationRoutes'); // New
const path = require('path');

// Routes
app.use('/auth', authRoutes);
app.use('/quiz', quizRoutes);
app.use('/ecg', ecgRoutes);
app.use('/shop', shopRoutes);
app.use('/stats', statsRoutes);
app.use('/social', socialRoutes);
app.use('/admin', adminRoutes); // New
app.use('/notifications', notificationRoutes); // New
app.use('/api', translateRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.get('/', (req, res) => {
    res.json({ message: 'AGOOM API is running', version: '1.0.0' });
});

app.get('/health', async (req, res) => {
    try {
        const result = await db.query('SELECT NOW()');
        res.json({ status: 'ok', db_time: result.rows[0].now });
    } catch (err) {
        console.error(err);
        res.status(500).json({ status: 'error', message: 'Database connection failed' });
    }
});

const PORT = process.env.PORT || 3000;

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
