import { Request, Response } from 'express';
import { AdaptiveEngineService } from '../services/AdaptiveEngineService';

export class StudyController {
    // Create an instance of the backend Adaptive Engine
    private engine = new AdaptiveEngineService();

    async getNext(req: Request, res: Response): Promise<void> {
        const user = (req as any).user;
        const userId = req.params.userId || user.id; // Support explicit param or fallback to Token
        const orgId = user.organizationId;
        const courseId = req.query.courseId as string | undefined;

        const question = await this.engine.getNextQuestion(userId, orgId, courseId);

        if (!question) {
            res.status(404).json({ error: 'No suitable questions found' });
            return;
        }

        res.json(question);
    }

    async submitAnswer(req: Request, res: Response): Promise<void> {
        const user = (req as any).user;
        const userId = user.id;
        const orgId = user.organizationId;
        const { questionId, quality, courseId } = req.body;

        await this.engine.processResult(userId, questionId, quality, courseId, orgId);
        res.json({ success: true });
    }
}
