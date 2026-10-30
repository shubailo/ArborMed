const quizController = require('../../../src/controllers/quizController');
const db = require('../../../src/config/db');
const pedagogicalEngine = require('../../../src/services/pedagogicalEngine');
const economyService = require('../../../src/services/economyService');

jest.mock('../../../src/config/db', () => ({
  query: jest.fn(),
}));

jest.mock('../../../src/services/pedagogicalEngine', () => ({
  resolveResponse: jest.fn(),
}));

jest.mock('../../../src/services/economyService', () => ({
  processQuizCoinReward: jest.fn(),
}));

jest.mock('../../../src/utils/dbHelpers', () => ({
  withTransaction: jest.fn((cb) => cb({})),
}));

describe('quizController Unit Tests', () => {
  let req;
  let res;
  let next;

  beforeEach(() => {
    jest.clearAllMocks();
    req = {
      user: { id: 42 },
      body: {},
    };
    res = {
      json: jest.fn(),
      status: jest.fn().mockReturnThis(),
    };
    next = jest.fn();
  });

  describe('submitAnswer', () => {
    it('evaluates True/False Hungarian "Hamis" against English "false" and awards stethoscope coins', async () => {
      req.body = {
        questionId: 14,
        userAnswer: 'Hamis',
        sessionId: '123',
        responseTimeMs: 2500,
      };

      // Mock question lookup
      db.query.mockImplementation((sql) => {
        if (typeof sql === 'string' && sql.includes('FROM questions')) {
          return Promise.resolve({
            rows: [
              {
                id: 14,
                question_type: 'true_false',
                correct_answer: 'false',
                explanation_en: 'Oxytocin is synthesized by the hypothalamus.',
                explanation_hu: 'Az oxitocint a hipotalamusz szintetizálja.',
                topic_slug: 'endocrinology',
                options: JSON.stringify([
                  { value: 'true', label: 'Igaz' },
                  { value: 'false', label: 'Hamis' },
                ]),
              },
            ],
          });
        }
        if (typeof sql === 'string' && sql.includes('INSERT INTO responses')) {
          return Promise.resolve({ rows: [{ id: 999 }] });
        }
        if (typeof sql === 'string' && sql.includes('INSERT INTO user_activity')) {
          return Promise.resolve({ rows: [] });
        }
        return Promise.resolve({ rows: [] });
      });

      pedagogicalEngine.resolveResponse.mockResolvedValue({
        mastery_score: 85,
        streak: 3,
        streakProgress: 0.6,
        level_correct_count: 5,
        srs: { easinessFactor: 2.5, interval: 3 },
      });

      economyService.processQuizCoinReward.mockResolvedValue(1);

      await quizController.submitAnswer(req, res, next);

      expect(next).not.toHaveBeenCalled();
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          isCorrect: true,
          correctAnswer: 'Hamis',
          explanation_hu: 'Az oxitocint a hipotalamusz szintetizálja.',
          coinsEarned: 1,
          streak: 3,
        })
      );
    });

    it('evaluates incorrect answer with isCorrect: false and 0 coins', async () => {
      req.body = {
        questionId: 14,
        userAnswer: 'Igaz',
        sessionId: '123',
        responseTimeMs: 2000,
      };

      db.query.mockImplementation((sql) => {
        if (typeof sql === 'string' && sql.includes('FROM questions')) {
          return Promise.resolve({
            rows: [
              {
                id: 14,
                question_type: 'true_false',
                correct_answer: 'false',
                explanation_hu: 'Az oxitocint a hipotalamusz szintetizálja.',
                topic_slug: 'endocrinology',
              },
            ],
          });
        }
        if (typeof sql === 'string' && sql.includes('INSERT INTO responses')) {
          return Promise.resolve({ rows: [{ id: 1000 }] });
        }
        return Promise.resolve({ rows: [] });
      });

      pedagogicalEngine.resolveResponse.mockResolvedValue({
        mastery_score: 80,
        streak: 0,
      });

      await quizController.submitAnswer(req, res, next);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          isCorrect: false,
          correctAnswer: 'Hamis',
          coinsEarned: 0,
        })
      );
      expect(economyService.processQuizCoinReward).not.toHaveBeenCalled();
    });

    it('returns 404 when question does not exist', async () => {
      req.body = { questionId: 99999, userAnswer: 'Hamis' };

      db.query.mockResolvedValue({ rows: [] });

      await quizController.submitAnswer(req, res, next);

      expect(next).toHaveBeenCalledWith(
        expect.objectContaining({
          statusCode: 404,
          message: 'Question not found',
        })
      );
    });
  });
});
