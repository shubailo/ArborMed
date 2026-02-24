
// Mock external dependencies virtually BEFORE requiring the module under test
jest.mock('socket.io', () => {
    return jest.fn(() => ({
        on: jest.fn(),
        to: jest.fn().mockReturnThis(),
        emit: jest.fn()
    }));
}, { virtual: true });

jest.mock('dotenv', () => ({
    config: jest.fn()
}), { virtual: true });

jest.mock('pg', () => ({
    Pool: jest.fn(() => ({
        on: jest.fn(),
        query: jest.fn()
    }))
}), { virtual: true });

const socketService = require('../../../src/services/socketService');
const db = require('../../../src/config/db');
const WalletService = require('../../../src/services/walletService');
const registry = require('../../../src/services/questionTypes/registry');

jest.mock('../../../src/config/db', () => ({
    query: jest.fn()
}));
jest.mock('../../../src/services/walletService', () => ({
    sinkWager: jest.fn(),
    refund: jest.fn(),
    awardPot: jest.fn()
}));

describe('SocketService Duel Validation', () => {
    let io;
    let connectionHandler;
    let mockSocket1;
    let mockSocket2;
    const handlers1 = {};
    const handlers2 = {};

    beforeEach(() => {
        jest.clearAllMocks();

        const mockIoInstance = {
            on: jest.fn((event, handler) => {
                if (event === 'connection') connectionHandler = handler;
            }),
            to: jest.fn().mockReturnThis(),
            emit: jest.fn()
        };
        require('socket.io').mockReturnValue(mockIoInstance);

        io = socketService.initializeSocket({}); // Mock server object

        mockSocket1 = {
            id: 's1',
            on: jest.fn((event, handler) => { handlers1[event] = handler; }),
            emit: jest.fn()
        };
        mockSocket2 = {
            id: 's2',
            on: jest.fn((event, handler) => { handlers2[event] = handler; }),
            emit: jest.fn()
        };

        connectionHandler(mockSocket1);
        connectionHandler(mockSocket2);
    });

    it('should sanitize questions by removing correct_answer and explanations', async () => {
        const mockQuestions = [
            {
                id: 1,
                question_type: 'single_choice',
                content: { question_text: 'Q1', options: ['A', 'B'] },
                correct_answer: 'A',
                explanation_en: 'Exp 1'
            }
        ];
        db.query.mockResolvedValue({ rows: mockQuestions });
        WalletService.sinkWager.mockResolvedValue(true);

        // Simulate socket 2 in queue
        await handlers2['join_queue']({ wager: 10, userId: 2 });
        // Simulate socket 1 joining and matching
        await handlers1['join_queue']({ wager: 10, userId: 1 });

        // Check emitted match_found for socket 1
        expect(io.to).toHaveBeenCalledWith('s1');
        const emittedData = io.emit.mock.calls.find(call => call[0] === 'match_found')[1];
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
                correct_answer: 'A'
            }
        ];
        db.query.mockResolvedValue({ rows: mockQuestions });
        WalletService.sinkWager.mockResolvedValue(true);

        // Start match
        await handlers2['join_queue']({ wager: 10, userId: 2 });
        await handlers1['join_queue']({ wager: 10, userId: 1 });

        const matchId = io.emit.mock.calls[0][1].matchId;

        // Submit correct answer from p1
        await handlers1['submit_answer']({ matchId, questionId: 1, answer: 'A' });

        // Verify score update
        expect(io.emit).toHaveBeenCalledWith('score_update', expect.objectContaining({ p1: 1, p2: 0 }));

        // Submit incorrect answer from p2
        await handlers2['submit_answer']({ matchId, questionId: 1, answer: 'B' });
        expect(io.emit).toHaveBeenCalledWith('score_update', expect.objectContaining({ p1: 1, p2: 0 }));
    });

    it('should prevent multiple submissions for the same question', async () => {
        const mockQuestions = [
            {
                id: 1,
                question_type: 'single_choice',
                content: { question_text: 'Q1', options: ['A', 'B'] },
                correct_answer: 'A'
            }
        ];
        db.query.mockResolvedValue({ rows: mockQuestions });
        WalletService.sinkWager.mockResolvedValue(true);

        // Start match
        await handlers2['join_queue']({ wager: 10, userId: 2 });
        await handlers1['join_queue']({ wager: 10, userId: 1 });

        const matchId = io.emit.mock.calls[0][1].matchId;

        // Submit correct answer from p1 twice
        await handlers1['submit_answer']({ matchId, questionId: 1, answer: 'A' });
        const emitCountAfterFirst = io.emit.mock.calls.length;

        await handlers1['submit_answer']({ matchId, questionId: 1, answer: 'A' });

        // Should not have emitted score_update again
        expect(io.emit.mock.calls.length).toBe(emitCountAfterFirst);
    });
});
