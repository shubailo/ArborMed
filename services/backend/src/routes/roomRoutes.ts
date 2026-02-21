import { Router } from 'express';
import { RoomController } from '../controllers/RoomController';
import { requireAuth } from '../middleware/auth';

const router = Router();
const controller = new RoomController();

// All room routes require authentication
router.use(requireAuth);

router.get('/', (req, res) => controller.getRoomState(req, res));
router.post('/place', (req, res) => controller.placeItem(req, res));
router.post('/clear', (req, res) => controller.clearSlot(req, res));

export default router;
