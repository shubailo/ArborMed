import { Router } from 'express';
import { StudyController } from '../controllers/StudyController';
import { RewardController } from '../controllers/RewardController';

const router = Router();
const studyController = new StudyController();

router.get('/next', studyController.getNext);
router.post('/answer', studyController.submitAnswer);

router.get('/shop', RewardController.getShopItems);
router.post('/purchase', RewardController.purchaseItem);
router.get('/room', RewardController.getRoomLayout);
router.post('/room', RewardController.updateRoomLayout);

export default router;
