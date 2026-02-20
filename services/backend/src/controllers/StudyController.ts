import { Request, Response } from 'express';
import { AdaptiveEngineService } from '../services/AdaptiveEngineService';

export class StudyController {
    private engine = new AdaptiveEngineService();

    getNext = async (req: Request, res: Response) => {
        try {
            const { orgId } = req.query;
            // Mock user for now
            const question = await this.engine.getNextQuestion('user-1', orgId as string);
            res.json(question);
        } catch (error) {
            res.status(500).json({ error: 'Failed to fetch next question' });
        }
    };

    submitAnswer = async (req: Request, res: Response) => {
        try {
            const { questionId, quality } = req.body;
            await this.engine.processResult('user-1', questionId, quality);
            res.sendStatus(200);
        } catch (error) {
            res.status(500).json({ error: 'Failed to submit answer' });
        }
    };
}
