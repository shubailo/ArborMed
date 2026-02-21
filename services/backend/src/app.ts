import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import studyRoutes from './routes/studyRoutes';
import analyticsRoutes from './routes/analyticsRoutes';
import authRoutes from './routes/authRoutes';
import rewardRoutes from './routes/rewardRoutes';
import roomRoutes from './routes/roomRoutes';
import progressRoutes from './routes/progressRoutes';
import socialRoutes from './routes/socialRoutes';
import debugRoutes from './routes/debugRoutes';
import { requireAuth } from './middleware/auth';
import { errorMiddleware } from './middleware/errorMiddleware';

import { prisma } from './db';
export { prisma };

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'medbuddy-backend' });
});

app.use('/auth', authRoutes);
app.use('/debug', debugRoutes);

app.use(requireAuth);

app.use('/study', studyRoutes);
app.use('/analytics', analyticsRoutes);
app.use('/rewards', rewardRoutes);
app.use('/room', roomRoutes);
app.use('/progress', progressRoutes);
app.use('/social', socialRoutes);

app.use(errorMiddleware);

app.listen(PORT, () => {
    console.log(`🚀 Med-Buddy Backend running on http://localhost:${PORT}`);
});
