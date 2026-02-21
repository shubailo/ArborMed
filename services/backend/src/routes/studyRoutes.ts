import { Router } from 'express';
import { StudyController } from '../controllers/StudyController';
import { RewardController } from '../controllers/RewardController';
import { RoomController } from '../controllers/RoomController';

const router = Router();
const studyController = new StudyController();
const rewardController = new RewardController();
const roomController = new RoomController();

router.get('/next', studyController.getNext);
router.post('/answer', studyController.submitAnswer);

router.get('/shop', rewardController.getShopItems);
router.post('/purchase', rewardController.purchaseItem);

router.get('/room', roomController.getRoomState);
router.post('/room', roomController.placeItem);

export default router;
