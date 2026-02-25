// Mock external dependencies virtually BEFORE requiring the module under test
jest.mock(
  'socket.io',
  () => {
    return jest.fn(() => ({
      on: jest.fn(),
      use: jest.fn(),
      to: jest.fn().mockReturnThis(),
      emit: jest.fn(),
    }));
  },
  { virtual: true }
);

jest.mock(
  'jsonwebtoken',
  () => ({
    verify: jest.fn((token, secret, cb) => {
      if (token === 'valid_token_1') cb(null, { id: 1 });
      else if (token === 'valid_token_2') cb(null, { id: 2 });
      else cb(new Error('Invalid token'));
    }),
  }),
  { virtual: true }
);

jest.mock(
  'dotenv',
  () => ({
    config: jest.fn(),
  }),
  { virtual: true }
);

jest.mock(
  'pg',
  () => ({
    Pool: jest.fn(() => ({
      on: jest.fn(),
      query: jest.fn(),
    })),
  }),
  { virtual: true }
);

jest.mock('../../../src/config/db', () => ({
  query: jest.fn(),
}));
jest.mock('../../../src/services/walletService', () => ({
  sinkWager: jest.fn(),
  refund: jest.fn(),
  awardPot: jest.fn(),
}));

describe('SocketService Duel Validation', () => {
  let io;
  let connectionHandler;
  let authMiddleware;
  let mockSocket1;
  let mockSocket2;
  let socketService;
  let db;
  let WalletService;
  const handlers1 = {};
  const handlers2 = {};

  beforeEach(() => {
    jest.resetModules(); // Reset module state (duelQueue)
    jest.clearAllMocks();

    // Re-mock dependencies after reset
    jest.mock(
      'socket.io',
      () => {
        return jest.fn(() => ({
          on: jest.fn(),
          use: jest.fn(),
          to: jest.fn().mockReturnThis(),
          emit: jest.fn(),
        }));
      },
      { virtual: true }
    );

    jest.mock(
      'jsonwebtoken',
      () => ({
        verify: jest.fn((token, secret, cb) => {
          if (token === 'valid_token_1') cb(null, { id: 1 });
          else if (token === 'valid_token_2') cb(null, { id: 2 });
          else cb(new Error('Invalid token'));
        }),
      }),
      { virtual: true }
    );

    jest.mock(
      'dotenv',
      () => ({
        config: jest.fn(),
      }),
      { virtual: true }
    );

    jest.mock(
      'pg',
      () => ({
        Pool: jest.fn(() => ({
          on: jest.fn(),
          query: jest.fn(),
        })),
      }),
      { virtual: true }
    );

    jest.mock('../../../src/config/db', () => ({
      query: jest.fn(),
    }));

    jest.mock('../../../src/services/walletService', () => ({
      sinkWager: jest.fn(),
      refund: jest.fn(),
      awardPot: jest.fn(),
    }));

    // Re-require the service under test
    socketService = require('../../../src/services/socketService');
    db = require('../../../src/config/db');
    WalletService = require('../../../src/services/walletService');

    const mockIoInstance = {
      on: jest.fn((event, handler) => {
        if (event === 'connection') connectionHandler = handler;
      }),
      use: jest.fn((middleware) => {
        authMiddleware = middleware;
      }),
      to: jest.fn().mockReturnThis(),
      emit: jest.fn(),
    };
    require('socket.io').mockReturnValue(mockIoInstance);

    io = socketService.initializeSocket({}); // Mock server object

    // Setup Socket 1
    mockSocket1 = {
      id: 's1',
      handshake: { auth: { token: 'valid_token_1' } },
      on: jest.fn((event, handler) => {
        handlers1[event] = handler;
      }),
      emit: jest.fn(),
    };

    // Setup Socket 2
    mockSocket2 = {
      id: 's2',
      handshake: { auth: { token: 'valid_token_2' } },
      on: jest.fn((event, handler) => {
        handlers2[event] = handler;
      }),
      emit: jest.fn(),
    };

    // Run middleware for both
    const next = jest.fn();
    if (authMiddleware) {
      authMiddleware(mockSocket1, next);
      authMiddleware(mockSocket2, next);
    }

    // Run connection handler
    if (connectionHandler) {
      connectionHandler(mockSocket1);
      connectionHandler(mockSocket2);
    }
  });

  it('should authenticate users and set socket.userId', () => {
    expect(mockSocket1.userId).toBe(1);
    expect(mockSocket2.userId).toBe(2);
  });

  it('should use authenticated userId for wallet operations', async () => {
    WalletService.sinkWager.mockResolvedValue(true);
    await handlers1['join_queue']({ wager: 10 });
    expect(WalletService.sinkWager).toHaveBeenCalledWith(1, 10);
  });

  it('should sanitize questions by removing correct_answer and explanations', async () => {
    const mockQuestions = [
      {
        id: 1,
        question_type: 'single_choice',
        content: { question_text: 'Q1', options: ['A', 'B'] },
        correct_answer: 'A',
        explanation_en: 'Exp 1',
      },
    ];
    db.query.mockResolvedValue({ rows: mockQuestions });
    WalletService.sinkWager.mockResolvedValue(true);

    // Simulate socket 2 in queue (Authenticated as user 2)
    await handlers2['join_queue']({ wager: 10 });
    // Simulate socket 1 joining (Authenticated as user 1)
    await handlers1['join_queue']({ wager: 10 });

    // Check emitted match_found for socket 1
    expect(io.to).toHaveBeenCalledWith('s1');
    // io.to().emit called twice (once for p1, once for p2)
    // Find the call for p1 match found
    const emitCalls = io.emit.mock.calls;

    const matchFoundCall = emitCalls.find(
      (call) => call[0] === 'match_found' && call[1].role === 'p1'
    );
    expect(matchFoundCall).toBeDefined();

    const emittedData = matchFoundCall[1];
    expect(emittedData.questions[0]).toHaveProperty('q');
    expect(emittedData.questions[0]).not.toHaveProperty('correct_answer');
    expect(emittedData.questions[0]).not.toHaveProperty('a');
    expect(emittedData.questions[0]).not.toHaveProperty('explanation');
    expect(emittedData.questions[0].id).toBe(1);
  });

  it('should validate answers on the server and update scores', async () => {
    const mockQuestions = [
      {
        id: 1,
        question_type: 'single_choice',
        content: { question_text: 'Q1', options: ['A', 'B'] },
        correct_answer: 'A',
      },
    ];
    db.query.mockResolvedValue({ rows: mockQuestions });
    WalletService.sinkWager.mockResolvedValue(true);

    // Start match
    await handlers2['join_queue']({ wager: 10 });
    await handlers1['join_queue']({ wager: 10 });

    const matchFoundCall = io.emit.mock.calls.find(
      (call) => call[0] === 'match_found'
    );
    const matchId = matchFoundCall[1].matchId;

    // Submit correct answer from p1
    await handlers1['submit_answer']({ matchId, questionId: 1, answer: 'A' });

    // Verify score update
    expect(io.emit).toHaveBeenCalledWith(
      'score_update',
      expect.objectContaining({ p1: 1, p2: 0 })
    );

    // Submit incorrect answer from p2
    await handlers2['submit_answer']({ matchId, questionId: 1, answer: 'B' });
    // Score remains p1: 1, p2: 0
    // The mock records all calls. We should see another score_update with same scores.
    expect(io.emit).toHaveBeenLastCalledWith(
      'score_update',
      expect.objectContaining({ p1: 1, p2: 0 })
    );
  });

  it('should prevent multiple submissions for the same question', async () => {
    const mockQuestions = [
      {
        id: 1,
        question_type: 'single_choice',
        content: { question_text: 'Q1', options: ['A', 'B'] },
        correct_answer: 'A',
      },
    ];
    db.query.mockResolvedValue({ rows: mockQuestions });
    WalletService.sinkWager.mockResolvedValue(true);

    // Start match
    await handlers2['join_queue']({ wager: 10 });
    await handlers1['join_queue']({ wager: 10 });

    const matchFoundCall = io.emit.mock.calls.find(
      (call) => call[0] === 'match_found'
    );
    const matchId = matchFoundCall[1].matchId;

    // Submit correct answer from p1 twice
    await handlers1['submit_answer']({ matchId, questionId: 1, answer: 'A' });
    const emitCountAfterFirst = io.emit.mock.calls.length;

    await handlers1['submit_answer']({ matchId, questionId: 1, answer: 'A' });

    // Should not have emitted score_update again (or anything else)
    expect(io.emit.mock.calls.length).toBe(emitCountAfterFirst);
  });
});
