const socketIo = require('socket.io');
const WalletService = require('./walletService');
const db = require('../config/db');
const registry = require('./questionTypes/registry');
const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');
const crypto = require('crypto');

let io;
const duelQueue = []; // Simple array for MVP matchmaking: [{id: socketId, wager: 5, timer: Timeout}]
const activeDuels = new Map(); // matchId -> { p1, p2, p1Score, p2Score, questions, timeRemaining }
const queueTimers = new Map(); // socketId -> Timeout

const BOT_NAMES = [
  'Dr. Kovács', 'Dr. Smith', 'Dr. Garcia', 'Dr. Müller', 'Dr. Rossi', 
  'Dr. Chen', 'Dr. Tanaka', 'Dr. Dubois', 'Dr. Ahmed', 'Dr. Petrov'
];

const initializeSocket = (server) => {
  io = socketIo(server, {
    cors: {
      origin: '*', // Allow all origins for MVP
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

      const opponentIndex = duelQueue.findIndex(
        (u) => u.wager === wager && u.id !== socket.id
      );

      if (opponentIndex > -1) {
        // MATCH FOUND!
        const opponent = duelQueue.splice(opponentIndex, 1)[0];
        
        // Clear timeout for the matched player
        if (queueTimers.has(opponent.id)) {
          clearTimeout(queueTimers.get(opponent.id));
          queueTimers.delete(opponent.id);
        }

        logger.info(`Match creating: ${socket.id} vs ${opponent.id}`);

        await createMatch(
          { id: socket.id, dbId: uId },
          { id: opponent.id, dbId: opponent.dbId },
          wager
        );
      } else {
        // NO MATCH -> WAIT
        duelQueue.push({ id: socket.id, dbId: uId, wager });
        socket.emit('queue_joined', { message: 'Waiting for opponent...' });

        // Start 30s Timeout for Bot Pairing
        const timer = setTimeout(() => {
          triggerBotMatch(socket.id, wager);
        }, 30000);
        queueTimers.set(socket.id, timer);
      }
    });

    socket.on('leave_queue', async () => {
      logger.info(`User ${socket.id} requested to leave queue`);
      if (queueTimers.has(socket.id)) {
        clearTimeout(queueTimers.get(socket.id));
        queueTimers.delete(socket.id);
      }
      const idx = duelQueue.findIndex((u) => u.id === socket.id);
      if (idx > -1) {
        const user = duelQueue[idx];
        await WalletService.refund(user.dbId, user.wager);
        duelQueue.splice(idx, 1);
        socket.emit('queue_left', { message: 'Left queue successfully', refundedWager: user.wager });
      }
    });

    // --- GAME LOGIC ---
    socket.on('submit_answer', ({ matchId, questionId, answer }) => {
      processAnswerSubmission(socket.id, matchId, questionId, answer);
    });

    socket.on('disconnect', () => {
      logger.info('Client disconnected:', socket.id);
      handleDisconnect(socket.id);
    });
  });

  return io;
};

// --- HELPERS ---

async function createMatch(p1Data, p2Data, wager) {
  const matchId = `match_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;
  
  // Fetch Questions
  const questions = await fetchDuelQuestions();

  // Create Match State
  activeDuels.set(matchId, {
    p1: { 
      id: p1Data.id, 
      dbId: p1Data.dbId, 
      answeredQuestions: new Set(),
      displayName: p1Data.displayName || 'You' 
    },
    p2: {
      id: p2Data.id,
      dbId: p2Data.dbId,
      answeredQuestions: new Set(),
      isBot: p2Data.isBot || false,
      displayName: p2Data.displayName || (p2Data.isBot ? 'Bot' : 'Opponent')
    },
    p1Score: 0,
    p2Score: 0,
    wager: wager,
    timeRemaining: 60,
    questions: questions,
    status: 'active',
  });

  const clientQuestions = questions.map((q) => {
    const clientQ = registry.prepareForClient(q);
    let questionText = q.text || (q.content && q.content.question_text) || 'Question missing';
    const sanitized = { ...clientQ, id: q.id, q: questionText };
    delete sanitized.correct_answer;
    delete sanitized.a;
    delete sanitized.explanation;
    return sanitized;
  });

  // Notify Player 1
  io.to(p1Data.id).emit('match_found', {
    matchId,
    opponentId: p2Data.id,
    opponentName: p2Data.displayName || 'Opponent',
    role: 'p1',
    questions: clientQuestions,
  });

  // Notify Player 2 (if not bot)
  if (!p2Data.isBot) {
    io.to(p2Data.id).emit('match_found', {
      matchId,
      opponentId: p1Data.id,
      opponentName: p1Data.displayName || 'Opponent',
      role: 'p2',
      questions: clientQuestions,
    });
  } else {
    // START BOT LOGIC
    simulateBotParticipation(matchId);
  }

  startMatchTimer(matchId);
}

function processAnswerSubmission(socketId, matchId, questionId, answer) {
  const match = activeDuels.get(matchId);
  if (!match || match.status !== 'active') return;

  const player = [match.p1, match.p2].find((p) => p.id === socketId);
  if (!player) return;

  if (player.answeredQuestions.has(questionId)) return;

  const question = match.questions.find((q) => String(q.id) === String(questionId));
  if (!question) return;

  const result = registry.checkAnswer(question, answer);
  player.answeredQuestions.add(questionId);

  if (result.correct) {
    if (player === match.p1) match.p1Score++;
    else match.p2Score++;
  }

  // Broadcast
  const syncData = { p1: match.p1Score, p2: match.p2Score };
  io.to(match.p1.id).emit('score_update', syncData);
  if (!match.p2.isBot) {
    io.to(match.p2.id).emit('score_update', syncData);
  }
}

async function triggerBotMatch(socketId, wager) {
  const idx = duelQueue.findIndex(u => u.id === socketId);
  if (idx === -1) return; // User already matched or left
  
  const user = duelQueue.splice(idx, 1)[0];
  queueTimers.delete(socketId);

  const botName = BOT_NAMES[Math.floor(Math.random() * BOT_NAMES.length)];
  const botId = `bot_${Date.now()}`;

  logger.info(`Starting bot match for ${socketId} against ${botName}`);

  await createMatch(
    { id: socketId, dbId: user.dbId },
    { id: botId, dbId: null, isBot: true, displayName: botName },
    wager
  );
}

function simulateBotParticipation(matchId) {
  const match = activeDuels.get(matchId);
  if (!match) return;

  // Bot answers each question with 70% accuracy at staggered times
  match.questions.forEach((q, index) => {
    // Calculate a delay: between 8s and 45s into the match
    const delay = 8000 + (index * 12000) + (Math.random() * 5000);
    
    setTimeout(() => {
      const currentMatch = activeDuels.get(matchId);
      if (!currentMatch || currentMatch.status !== 'active') return;

      const isCorrect = Math.random() < 0.7;
      let botAnswer;

      if (isCorrect) {
        botAnswer = q.correct_answer;
      } else {
        // Basic wrong answer selection for MVP
        if (q.question_type === 'single_choice' && q.content?.options) {
          const wrongs = q.content.options.filter(o => o !== q.correct_answer);
          botAnswer = wrongs[Math.floor(Math.random() * wrongs.length)] || 'Wrong';
        } else {
          botAnswer = 'Wrong Choice';
        }
      }

      processAnswerSubmission(currentMatch.p2.id, matchId, q.id, botAnswer);
      logger.info(`Bot ${currentMatch.p2.displayName} submitted answer for match ${matchId}`);
    }, delay);
  });
}

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
      if (!match.p2.isBot) {
        io.to(match.p2.id).emit('time_sync', { time: match.timeRemaining });
      }
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

  const p1Won = winnerSocket === match.p1.id;
  const isDraw = winnerSocket === 'draw';

  io.to(match.p1.id).emit('game_over', {
    winner: winnerSocket,
    isWinner: p1Won,
    isDraw: isDraw,
    potWon: p1Won ? match.wager * 2 : (isDraw ? match.wager : 0),
    wager: match.wager,
    myScore: match.p1Score,
    opScore: match.p2Score,
  });
  if (!match.p2.isBot) {
    const p2Won = winnerSocket === match.p2.id;
    io.to(match.p2.id).emit('game_over', {
      winner: winnerSocket,
      isWinner: p2Won,
      isDraw: isDraw,
      potWon: p2Won ? match.wager * 2 : (isDraw ? match.wager : 0),
      wager: match.wager,
      myScore: match.p2Score,
      opScore: match.p1Score,
    });
  }

  logger.info(`Match ${matchId} ended. Winner: ${winnerSocket}`);
  activeDuels.delete(matchId);
}

function handleDisconnect(socketId) {
  // Clear any queue timers
  if (queueTimers.has(socketId)) {
    clearTimeout(queueTimers.get(socketId));
    queueTimers.delete(socketId);
  }

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
      if (winner.dbId) {
        WalletService.awardPot(winner.dbId, match.wager * 2);
      }

      if (!winner.isBot) {
        io.to(winner.id).emit('opponent_disconnected', { win: true, potWon: match.wager * 2 });
      }
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
