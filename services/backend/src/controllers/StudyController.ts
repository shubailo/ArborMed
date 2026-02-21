import { Request, Response } from 'express';
import { AdaptiveEngineService } from '../services/AdaptiveEngineService';

export class StudyController {
    // Create an instance of the backend Adaptive Engine
    private engine = new AdaptiveEngineService();

    getNext = async (req: Request, res: Response): Promise<void> => {
        const user = (req as any).user;
        if (!user) {
            console.error('[StudyController] ERROR: User undefined in getNext');
            res.status(401).json({ error: 'Authentication required' });
            return;
        }

        const userId = req.params.userId || user.id;
        const orgId = user.organizationId;
        const courseId = req.query.courseId as string | undefined;

        try {
            const question = await this.engine.getNextQuestion(userId, orgId, courseId);

            if (!question) {
                res.status(404).json({ error: 'No suitable questions found' });
                return;
            }

            res.json(question);
        } catch (error) {
            console.error('[StudyController] getNext error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    submitAnswer = async (req: Request, res: Response): Promise<void> => {
        const user = (req as any).user;
        if (!user) {
            res.status(401).json({ error: 'Authentication required' });
            return;
        }

        const userId = user.id;
        const orgId = user.organizationId;
        const { questionId, quality, courseId } = req.body;

        try {
            await this.engine.processResult(userId, questionId, quality, courseId, orgId);

            // M3: Reward System Integration
            const { RewardService } = await import('../services/RewardService');
            const newBalance = await RewardService.addRewardPoints(userId, quality);

            res.json({ success: true, rewardBalance: newBalance });
        } catch (error) {
            console.error('[StudyController] submitAnswer error:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
}
