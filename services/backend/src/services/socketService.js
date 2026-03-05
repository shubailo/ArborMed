const socketIo = require('socket.io');
const WalletService = require('./walletService');
const db = require('../config/db');
const registry = require('./questionTypes/registry');
const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

let io;
const duelQueue = []; // Simple array for MVP matchmaking: [{id: socketId, wager: 5}]
const activeDuels = new Map(); // matchId -> { p1, p2, p1Score, p2Score, questions, timeRemaining }

const initializeSocket = (server) => {
  const allowedOrigins = process.env.ALLOWED_ORIGINS
    ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
    : [];

  io = socketIo(server, {
    cors: {
      origin: (origin, callback) => {
        if (
          !origin ||
          process.env.NODE_ENV === 'development' ||
          allowedOrigins.includes(origin)
        ) {
          callback(null, true);
        } else {
          callback(new Error('Not allowed by CORS'));
        }
      },
      methods: ['GET', 'POST'],
    },
  });

  // Authentication Middleware
  io.use((socket, next) => {
    const token =
      socket.handshake.auth.token ||
      (socket.handshake.headers.authorization &&
        socket.handshake.headers.authorization.split(' ')[1]);

    if (!token) {
      return next(new Error('Authentication error'));
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
      if (err) return next(new Error('Authentication error'));
      socket.userId = decoded.id;
      next();
    });
  });

  io.on('connection', (socket) => {
    logger.info('New client connected:', socket.id);

    // --- LOBBY LOGIC ---
    socket.on('join_queue', async ({ wager }) => {
      logger.info(`User ${socket.id} joining queue for ${wager} coins`);

      const uId = socket.userId;

      // 1. Validate Funds
      const hasFunds = await WalletService.sinkWager(uId, wager);
      if (!hasFunds) {
        socket.emit('error', { message: 'Insufficient funds' });
        return;
      }

      // 2. Check matchmaking
      const opponentIndex = duelQueue.findIndex(
        (u) => u.wager === wager && u.id !== socket.id
      );

      if (opponentIndex > -1) {
        // MATCH FOUND!
        const opponent = duelQueue.splice(opponentIndex, 1)[0];
        const matchId = `match_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;

        logger.info(`Match creating: ${socket.id} vs ${opponent.id}`);

        // Fetch Questions
        const questions = await fetchDuelQuestions();

        // Create Match State
        activeDuels.set(matchId, {
          p1: { id: socket.id, dbId: uId, answeredQuestions: new Set() },
          p2: {
            id: opponent.id,
            dbId: opponent.dbId,
            answeredQuestions: new Set(),
          },
          p1Score: 0,
          p2Score: 0,
          wager: wager,
          timeRemaining: 60,
          questions: questions,
          status: 'active',
        });

        // Sanitize questions for client (remove answers)
        const clientQuestions = questions.map((q) => {
          const clientQ = registry.prepareForClient(q);

          // Standardize structure while maintaining some backward compatibility
          let questionText = q.text;
          if (q.content && q.content.question_text) {
            questionText = q.content.question_text;
          }

          const sanitized = {
            ...clientQ,
            id: q.id,
            q: questionText || 'Question text missing', // Backward compatibility
          };

          // Ensure answers and explanations are removed
          delete sanitized.correct_answer;
          delete sanitized.a; // Backward compatibility
          delete sanitized.explanation;
          delete sanitized.explanation_en;
          delete sanitized.explanation_hu;

          return sanitized;
        });

        // Notify Players
        io.to(socket.id).emit('match_found', {
          matchId,
          opponentId: opponent.id,
          role: 'p1',
          questions: clientQuestions,
        });
        io.to(opponent.id).emit('match_found', {
          matchId,
          opponentId: socket.id,
          role: 'p2',
          questions: clientQuestions,
        });

        // Start Timer
        startMatchTimer(matchId);
      } else {
        // NO MATCH -> WAIT
        duelQueue.push({ id: socket.id, dbId: uId, wager });
        socket.emit('queue_joined', { message: 'Waiting for opponent...' });
      }
    });

    // --- GAME LOGIC ---
    socket.on('submit_answer', ({ matchId, questionId, answer }) => {
      const match = activeDuels.get(matchId);
      if (!match || match.status !== 'active') return;

      const player =
        socket.id === match.p1.id
          ? match.p1
          : socket.id === match.p2.id
            ? match.p2
            : null;
      if (!player) return;

      // Prevent duplicate answers for the same question
      if (player.answeredQuestions.has(questionId)) return;

      const question = match.questions.find(
        (q) => String(q.id) === String(questionId)
      );
      if (!question) return;

      // Validate answer on server-side
      const result = registry.checkAnswer(question, answer);

      player.answeredQuestions.add(questionId);
      if (result.correct) {
        if (player === match.p1) match.p1Score++;
        else match.p2Score++;
      }

      // Broadcast score update to BOTH players
      io.to(match.p1.id).emit('score_update', {
        p1: match.p1Score,
        p2: match.p2Score,
      });
      io.to(match.p2.id).emit('score_update', {
        p1: match.p1Score,
        p2: match.p2Score,
      });
    });

    socket.on('disconnect', () => {
      logger.info('Client disconnected:', socket.id);
      handleDisconnect(socket.id);
    });
  });

  return io;
};

// --- HELPERS ---

function startMatchTimer(matchId) {
  const interval = setInterval(() => {
    const match = activeDuels.get(matchId);
    if (!match) {
      clearInterval(interval);
      return;
    }

    match.timeRemaining--;

    // Sync time every 5s or on end
    if (match.timeRemaining % 5 === 0 || match.timeRemaining <= 0) {
      io.to(match.p1.id).emit('time_sync', { time: match.timeRemaining });
      io.to(match.p2.id).emit('time_sync', { time: match.timeRemaining });
    }

    if (match.timeRemaining <= 0) {
      clearInterval(interval);
      endMatch(matchId);
    }
  }, 1000);
}

async function endMatch(matchId) {
  const match = activeDuels.get(matchId);
  if (!match) return;

  match.status = 'finished';
  let winnerSocket;
  let winnerDbId = null;

  if (match.p1Score > match.p2Score) {
    winnerSocket = match.p1.id;
    winnerDbId = match.p1.dbId;
  } else if (match.p2Score > match.p1Score) {
    winnerSocket = match.p2.id;
    winnerDbId = match.p2.dbId;
  } else {
    // DRAW: Refund both
    await WalletService.refund(match.p1.dbId, match.wager);
    await WalletService.refund(match.p2.dbId, match.wager);
    winnerSocket = 'draw';
  }

  // WINNER TAKES ALL (2 * Wager)
  if (winnerDbId) {
    await WalletService.awardPot(winnerDbId, match.wager * 2);
  }

  io.to(match.p1.id).emit('game_over', {
    winner: winnerSocket,
    myScore: match.p1Score,
    opScore: match.p2Score,
  });
  io.to(match.p2.id).emit('game_over', {
    winner: winnerSocket,
    myScore: match.p2Score,
    opScore: match.p1Score,
  });

  logger.info(`Match ${matchId} ended. Winner: ${winnerSocket}`);
  activeDuels.delete(matchId);
}

function handleDisconnect(socketId) {
  // Remove from queue
  const idx = duelQueue.findIndex((u) => u.id === socketId);
  if (idx > -1) {
    // Refund if waiting in queue
    const user = duelQueue[idx];
    WalletService.refund(user.dbId, user.wager);
    duelQueue.splice(idx, 1);
  }

  // Forfeit active matches
  for (const [matchId, match] of activeDuels.entries()) {
    if (match.p1.id === socketId || match.p2.id === socketId) {
      const winner = match.p1.id === socketId ? match.p2 : match.p1;

      // AUTO WIN for survivor
      WalletService.awardPot(winner.dbId, match.wager * 2);

      io.to(winner.id).emit('opponent_disconnected', { win: true });
      activeDuels.delete(matchId); // Immediate cleanup on MVP
    }
  }
}

async function fetchDuelQuestions(count = 3) {
  try {
    const result = await db.query(
      'SELECT * FROM questions WHERE active = TRUE ORDER BY RANDOM() LIMIT $1',
      [count]
    );

    return result.rows;
  } catch (err) {
    logger.error('Error fetching duel questions:', err);
    // Fallback to basic questions if DB fails (e.g. during dev without DB)
    return [
      {
        id: 'fallback_1',
        question_type: 'single_choice',
        content: {
          question_text: 'What is the powerhouse of the cell?',
          options: ['Mitochondria', 'Nucleus', 'Ribosome', 'Golgi'],
        },
        correct_answer: 'Mitochondria',
      },
      {
        id: 'fallback_2',
        question_type: 'single_choice',
        content: {
          question_text: 'Normal HR range?',
          options: ['60-100', '40-60', '100-120', '80-120'],
        },
        correct_answer: '60-100',
      },
      {
        id: 'fallback_3',
        question_type: 'single_choice',
        content: {
          question_text: 'Capital of France?',
          options: ['Paris', 'London', 'Berlin', 'Madrid'],
        },
        correct_answer: 'Paris',
      },
    ];
  }
}

module.exports = { initializeSocket };
