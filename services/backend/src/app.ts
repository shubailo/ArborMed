import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import studyRoutes from './routes/studyRoutes';
import analyticsRoutes from './routes/analyticsRoutes';
import authRoutes from './routes/authRoutes';
import { requireAuth } from './middleware/auth';
import { errorMiddleware } from './middleware/errorMiddleware';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'medbuddy-backend' });
});

app.use('/auth', authRoutes);

app.use(requireAuth);

app.use('/study', studyRoutes);
app.use('/analytics', analyticsRoutes);

app.use(errorMiddleware);

app.listen(PORT, () => {
    console.log(`🚀 Med-Buddy Backend running on http://localhost:${PORT}`);
});
