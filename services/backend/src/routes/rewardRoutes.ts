import { Router } from 'express';
import { RewardController } from '../controllers/RewardController';
import { requireAuth } from '../middleware/auth';

const router = Router();
const controller = new RewardController();

// All reward routes require authentication
router.use(requireAuth);

router.get('/balance/:userId?', (req, res) => controller.getBalance(req, res));
router.get('/shop', (req, res) => controller.getShopItems(req, res));
router.get('/inventory', (req, res) => controller.getInventory(req, res));
router.post('/purchase', (req, res) => controller.purchaseItem(req, res));

export default router;
