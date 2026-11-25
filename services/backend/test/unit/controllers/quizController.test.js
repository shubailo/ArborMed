const quizController = require('../../../src/controllers/quizController');
const db = require('../../../src/config/db');
const pedagogicalEngine = require('../../../src/services/pedagogicalEngine');
const economyService = require('../../../src/services/economyService');

jest.mock('../../../src/config/db', () => ({
  query: jest.fn(),
}));

jest.mock('../../../src/services/pedagogicalEngine', () => ({
  resolveResponse: jest.fn(),
  getChallenge: jest.fn(),
}));

jest.mock('../../../src/services/economyService', () => ({
  processQuizCoinReward: jest.fn(),
}));

jest.mock('../../../src/utils/dbHelpers', () => ({
  withTransaction: jest.fn((cb) => cb(require('../../../src/config/db'))),
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

  it('lists registered question types', async () => {
    await quizController.getQuestionTypes(req, res, next);
    expect(res.json).toHaveBeenCalledWith(expect.arrayContaining([
      expect.objectContaining({ id: 'single_choice' }),
    ]));
  });

  it('skips an unusable legacy candidate and lets the engine select an overdue review', async () => {
    req.query = {topic: 'renal', bloomLevel: '1', exclude: '7'};
    pedagogicalEngine.getChallenge.mockResolvedValueOnce({id: 8, options: ['A','B'], correct_answer: 'absent'})
      .mockResolvedValueOnce({id: 9, options: ['A','B'], correct_answer: 'B', selectionReason: 'SRS_REVIEW'});
    await quizController.getNextQuestion(req, res, next);
    expect(pedagogicalEngine.getChallenge.mock.calls).toEqual([[42,'renal',[7]],[42,'renal',[7,8]]]);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({id:9, selectionReason:'SRS_REVIEW'}));
  });

  describe('submitAnswer', () => {
    it('returns the original result without a second progression or coin update on retry', async () => {
      const result = { isCorrect: true, coinsEarned: 1 };
      req.body = { submissionId: 'eeabf5b6-cc45-475b-8ab0-55fb047561f9', questionId: 8, userAnswer: 'A' };
      db.query.mockImplementation(async (sql) => ({
        rows: sql.includes('FROM responses')
          ? [{ question_id: 8, submission_input: 'A', submission_result: result }] : [],
      }));
      await quizController.submitAnswer(req, res, next);
      expect(res.json).toHaveBeenCalledWith(result);
      expect(pedagogicalEngine.resolveResponse).not.toHaveBeenCalled();
      expect(economyService.processQuizCoinReward).not.toHaveBeenCalled();
    });

    it('rejects a reused submission ID carrying a different answer', async () => {
      req.body = { submissionId: 'eeabf5b6-cc45-475b-8ab0-55fb047561f9', questionId: 8, userAnswer: 'B' };
      db.query.mockImplementation(async (sql) => ({
        rows: sql.includes('FROM responses')
          ? [{ question_id: 8, submission_input: 'A', submission_result: {} }] : [],
      }));
      await quizController.submitAnswer(req, res, next);
      expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode: 409 }));
      expect(pedagogicalEngine.resolveResponse).not.toHaveBeenCalled();
    });
    it('evaluates True/False Hungarian "Hamis" against English "false" and awards stethoscope coins', async () => {
      req.body = { submissionId: 'eeabf5b6-cc45-475b-8ab0-55fb047561f9',
        questionId: 14,
        userAnswer: 'Hamis',
        sessionId: '123',
        responseTimeMs: 2500,
      };

      // Mock question lookup
      db.query.mockImplementation((sql) => {
        if (sql.includes('SET reward_day')) return Promise.resolve({rows: [{ id: 999 }]});
        if (sql.includes('FROM quiz_sessions')) return Promise.resolve({ rows: [{ id: 123 }] });
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
      req.body = { submissionId: 'eeabf5b6-cc45-475b-8ab0-55fb047561f9',
        questionId: 14,
        userAnswer: 'Igaz',
        quality: 5,
        sessionId: '123',
        responseTimeMs: 2000,
      };

      db.query.mockImplementation((sql) => {
        if (sql.includes('FROM quiz_sessions')) return Promise.resolve({ rows: [{ id: 123 }] });
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
      expect(pedagogicalEngine.resolveResponse).toHaveBeenCalledWith(42, 'endocrinology', 14, false, 2, 2000, expect.anything());
    });

    it('rejects malformed quality before opening a transaction', async () => {
      req.body = {questionId: 14, userAnswer: 'A', quality: 'high'};
      await quizController.submitAnswer(req, res, next);
      expect(next).toHaveBeenCalledWith(expect.objectContaining({statusCode: 400}));
      expect(db.query).not.toHaveBeenCalled();
    });

    it('returns 404 when question does not exist', async () => {
      req.body = { submissionId: 'eeabf5b6-cc45-475b-8ab0-55fb047561f9', questionId: 99999, userAnswer: 'Hamis' };

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
