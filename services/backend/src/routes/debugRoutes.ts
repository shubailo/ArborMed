import { Router } from 'express';
import { DebugController } from '../controllers/DebugController';

const router = Router();

router.get('/engine-decisions', DebugController.getEngineDecisions);
router.get('/study-sessions', DebugController.getStudySessions);

export default router;
