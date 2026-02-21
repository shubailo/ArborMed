import { Router } from 'express';
import { SocialController } from '../controllers/SocialController';

const router = Router();
const socialController = new SocialController();

// GET /social/course/:courseId/clinic-directory
router.get('/course/:courseId/clinic-directory', socialController.getClinicDirectory);

// GET /social/room/:userId/preview?courseId=...
router.get('/room/:userId/preview', socialController.visitRoom);

export default router;
