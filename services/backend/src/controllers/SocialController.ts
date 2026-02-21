import { Request, Response, NextFunction } from 'express';
import { SocialService } from '../services/SocialService';

// Add user property to Request object for authenticated routes
interface AuthRequest extends Request {
    user?: {
        userId: string;
        roles: string[];
    };
}

export class SocialController {
    /**
     * Fetch clinic directory for a specific course
     */
    async getClinicDirectory(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
        try {
            const courseId = req.params.courseId;

            if (!courseId) {
                res.status(400).json({ success: false, error: 'courseId is required.' });
                return;
            }

            const directory = await SocialService.getClinicDirectory(courseId);

            res.json({
                success: true,
                data: directory
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Visit another student's room (read-only view)
     */
    async visitRoom(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
        try {
            const targetUserId = req.params.userId;
            const courseId = req.query.courseId as string;
            const visitorUserId = req.user?.userId;

            if (!targetUserId) {
                res.status(400).json({ success: false, error: 'Target userId is required.' });
                return;
            }

            if (!courseId) {
                res.status(400).json({ success: false, error: 'courseId query parameter is required.' });
                return;
            }

            if (!visitorUserId) {
                res.status(401).json({ success: false, error: 'Unauthorized.' });
                return;
            }

            const visitDto = await SocialService.getRoomVisit(visitorUserId, targetUserId, courseId);

            res.json({
                success: true,
                data: visitDto
            });
        } catch (error: any) {
            if (error.errorCode === 'UNAUTHORIZED_VISIT') {
                res.status(403).json({ success: false, error: error.message });
                return;
            }
            next(error);
        }
    }
}
