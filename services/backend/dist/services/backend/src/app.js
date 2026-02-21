"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.prisma = void 0;
require("dotenv/config");
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const studyRoutes_1 = __importDefault(require("./routes/studyRoutes"));
const analyticsRoutes_1 = __importDefault(require("./routes/analyticsRoutes"));
const authRoutes_1 = __importDefault(require("./routes/authRoutes"));
const rewardRoutes_1 = __importDefault(require("./routes/rewardRoutes"));
const roomRoutes_1 = __importDefault(require("./routes/roomRoutes"));
const progressRoutes_1 = __importDefault(require("./routes/progressRoutes"));
const debugRoutes_1 = __importDefault(require("./routes/debugRoutes"));
const auth_1 = require("./middleware/auth");
const errorMiddleware_1 = require("./middleware/errorMiddleware");
const db_1 = require("./db");
Object.defineProperty(exports, "prisma", { enumerable: true, get: function () { return db_1.prisma; } });
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'medbuddy-backend' });
});
app.use('/auth', authRoutes_1.default);
app.use('/debug', debugRoutes_1.default);
app.use(auth_1.requireAuth);
app.use('/study', studyRoutes_1.default);
app.use('/analytics', analyticsRoutes_1.default);
app.use('/rewards', rewardRoutes_1.default);
app.use('/room', roomRoutes_1.default);
app.use('/progress', progressRoutes_1.default);
app.use(errorMiddleware_1.errorMiddleware);
app.listen(PORT, () => {
    console.log(`🚀 Med-Buddy Backend running on http://localhost:${PORT}`);
});
