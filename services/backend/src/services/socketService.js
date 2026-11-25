const socketIo = require('socket.io');
const { verifyAccessToken } = require('../utils/accessToken');
const { randomUUID } = require('crypto');
const db = require('../config/db');
const { findSessionUser } = require('./sessionUser');
const { isAllowedOrigin, corsOrigin } = require('../config/origins');
const wallet = require('./walletService');
const { choiceOptions, gradeChoices } = require('./questionTypes/choiceOptions');
const logger = require('../utils/logger');

const members = new Map(); // One pending join, queue slot, or active match per account.
const matches = new Map();
const botNames = ['Dr. Kov\u00e1cs', 'Dr. Smith', 'Dr. Garcia', 'Dr. M\u00fcller', 'Dr. Rossi'];
let recoveryTimer;
let io;

function initializeSocket(server) {
  io = socketIo(server, {
    cors: { origin: corsOrigin, methods: ['GET', 'POST'] },
    allowRequest: (req, callback) => callback(null, isAllowedOrigin(req.headers.origin))
  });
  io.use(async (socket, next) => {
    const token = socket.handshake.auth?.token ||
      /^Bearer\s+(\S+)$/i.exec(socket.handshake.headers.authorization || '')?.[1];
    if (!token) return next(new Error('Authentication error'));
    try {
      const decoded = verifyAccessToken(token);
      const user = await findSessionUser(decoded);
      if (!user) return next(new Error('Authentication error'));
      socket.userId = user.id;
      socket.accessToken = token;
    } catch {
      return next(new Error('Authentication error'));
    }
    next();
  });

  io.on('connection', socket => {
    socket.on('join_queue', data => join(socket, data?.wager, data?.token ?? socket.accessToken));
    socket.on('duel_result_request', data => sendReceipt(socket, data?.matchId, data?.token ?? socket.accessToken));
    socket.on('leave_queue', () => leave(socket, false));
    socket.on('disconnect', () => leave(socket, true));
    socket.on('submit_answer', data => submit(socket, data));
  });

  let recovering = false;
  const recover = async () => {
    if (recovering) return;
    recovering = true;
    try {
      await wallet.recoverExpired();
    } catch (error) {
      logger.error('Duel wager recovery failed', error);
    } finally {
      recovering = false;
    }
  };
  recover();
  recoveryTimer = setInterval(recover, 30000);
  recoveryTimer.unref();
  return io;
}

function forget(member) {
  clearTimeout(member.timer);
  if (members.get(member.socket.userId) === member) members.delete(member.socket.userId);
}

async function refund(member, unannouncedMatchId = null) {
  member.state = 'closing';
  clearTimeout(member.timer);
  try {
    const refunded = await wallet.cancel(member.hold, unannouncedMatchId);
    member.socket.emit('queue_left', { refundedWager: refunded ? member.wager : 0 });
  } catch (error) {
    logger.error('Duel reservation refund deferred to recovery', error);
    member.socket.emit('error', { message: 'Refund pending. Your wallet will update automatically.' });
  } finally {
    forget(member);
  }
}

async function join(socket, wager, token) {
  if (!wallet.isAllowedWager(wager)) return socket.emit('error', { message: 'Invalid wager' });
  if (members.has(socket.userId)) {
    // A repeated tap on the same socket should not replace its current screen.
    if (members.get(socket.userId).socket !== socket) socket.emit('error', { message: 'A duel is already pending' });
    return;
  }
  let session;
  try {
    session = verifyAccessToken(token);
    if (session.id !== socket.userId) throw new Error('Account mismatch');
  } catch {
    return socket.emit('error', { message: 'Session expired. Refresh your account to join a duel.' });
  }
  const member = { socket, wager, hold: randomUUID(), state: 'joining' };
  members.set(socket.userId, member);
  try {
    if (!await wallet.reserve(member.hold, socket.userId, wager, session)) {
      forget(member);
      return socket.emit('error', { message: 'Insufficient funds or an outstanding wager' });
    }
    if (member.left) return refund(member);
    const opponent = [...members.values()].find(candidate => candidate.state === 'queued' && candidate.wager === wager);
    if (opponent) return formMatch(member, opponent);

    member.state = 'queued';
    socket.emit('queue_joined', { message: 'Waiting for opponent...' });
    member.timer = setTimeout(() => formMatch(member, null), 30000);
  } catch (error) {
    logger.error('Duel reservation failed', error);
    // The debit may have committed even if its acknowledgement never arrived.
    await refund(member);
    socket.emit('error', { message: 'Unable to reserve this wager' });
  }
}

async function leave(socket, disconnected) {
  const member = members.get(socket.userId);
  if (member?.socket !== socket) {
    if (!disconnected) socket.emit('queue_left', {refundedWager: 0});
    return;
  }
  if (member.state === 'playing') {
    if (disconnected) {
      const match = matches.get(member.matchId);
      if (match) return finish(match, Date.now() >= match.endsAt ? winner(match) : (member === match.p1 ? 'p2' : 'p1'));
    }
    return;
  }
  member.left = true;
  if (member.state === 'queued') return refund(member);
  // In-flight reservations and match creation observe left before announcing a match.
}

// The duel UI renders a single choice. Never send a database row, answer
// metadata, or the database's reusable practice question ID to a contestant.
async function fetchQuestions() {
  const { rows } = await db.query(`
    SELECT question_text_en, question_text_hu, options, content, correct_answer, question_type
    FROM questions WHERE active AND question_type = 'single_choice' ORDER BY RANDOM() LIMIT 12`);
  const questions = [];
  for (const row of rows) {
    const text = row.question_text_en || row.question_text_hu || row.content?.question_text;
    if (typeof text !== 'string' || !text.trim()) continue;
    const choices = choiceOptions(row);
    const labels = choices.map(choice => choice.en || choice.hu);
    if (choices.length < 2 || labels.some(label => typeof label !== 'string' || !label.trim())
        || new Set(labels).size !== labels.length) continue;
    const correct = choices.filter(choice => gradeChoices(row, choice.id).correct);
    if (correct.length !== 1) continue;
    questions.push({
      public: {id: questions.length + 1, q: text, options: labels},
      correct: correct[0].en || correct[0].hu
    });
    if (questions.length === 3) break;
  }
  return questions;
}

async function formMatch(p1, p2) {
  const players = p2 ? [p1, p2] : [p1];
  for (const member of players) {
    member.state = 'forming';
    clearTimeout(member.timer);
  }
  const id = randomUUID();
  try {
    const questions = await fetchQuestions();
    if (!questions.length) throw new Error('No playable duel questions');
    if (players.some(p => p.left)) return Promise.all(players.map(p => refund(p)));
    if (!await wallet.start(id, players.map(p => p.hold), p1.wager)) throw new Error('Reservation expired');

    const match = { id, p1, p2, questions, endsAt: Date.now() + 60000, scores: {p1:0, p2:0},
      answers: {p1:new Set(), p2:new Set()}, timers: [], state: 'active' };
    matches.set(id, match);
    for (const p of players) { p.state = 'playing'; p.matchId = id; }
    if (players.some(p => p.left)) {
      match.cancelled = true;
      return finish(match, 'draw');
    }

    const publicQuestions = questions.map(q => q.public);
    const botName = botNames[Math.floor(Math.random() * botNames.length)];
    for (const member of players) {
      const other = member === p1 ? p2 : p1;
      io.to(member.socket.id).emit('match_found', {
        matchId: id, opponentId: other?.socket.id || 'bot', opponentName: other ? 'Opponent' : botName,
        role: member === p1 ? 'p1' : 'p2', questions: publicQuestions
      });
    }
    if (!p2) {
      for (const [index, question] of questions.entries()) {
        match.timers.push(setTimeout(() => record(match, 'p2', question, Math.random() < 0.7),
          8000 + index * 12000 + Math.random() * 5000));
      }
    }
    match.clock = setInterval(() => {
      const time = Math.max(0, Math.ceil((match.endsAt - Date.now()) / 1000));
      broadcast(match, 'time_sync', {time});
      if (!time) finish(match, winner(match));
    }, 5000);
  } catch (error) {
    logger.error('Unable to create duel', error);
    await Promise.all(players.map(p => refund(p, id)));
    for (const p of players) p.socket.emit('error', {message: 'Unable to start the duel. Check your wallet for your refund.'});
  }
}

function broadcast(match, event, payload) {
  io.to(match.p1.socket.id).emit(event, payload);
  if (match.p2) io.to(match.p2.socket.id).emit(event, payload);
}

function submit(socket, data) {
  const member = members.get(socket.userId);
  const match = matches.get(data?.matchId);
  if (!match || member?.socket !== socket || member.matchId !== match.id || Date.now() >= match.endsAt) return;
  const question = match.questions.find(q => String(q.public.id) === String(data.questionId));
  if (!question || !question.public.options.includes(data.answer)) return;
  record(match, member === match.p1 ? 'p1' : 'p2', question, data.answer === question.correct);
}

function record(match, role, question, correct) {
  const id = question.public.id;
  if (match.state !== 'active' || Date.now() >= match.endsAt || match.answers[role].has(id)) return;
  match.answers[role].add(id);
  if (correct) match.scores[role]++;
  broadcast(match, 'score_update', {...match.scores});
}

function winner(match) {
  if (match.scores.p1 === match.scores.p2) return 'draw';
  return match.scores.p1 > match.scores.p2 ? 'p1' : 'p2';
}

function stopTimers(match) {
  clearInterval(match.clock);
  match.timers.forEach(clearTimeout);
}

async function finish(match, result) {
  if (match.state !== 'active') return;
  match.state = 'closing';
  stopTimers(match);
  await settle(match, result);
}

async function sendReceipt(socket, matchId, token) {
  if (typeof matchId !== 'string' || !/^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$/i.test(matchId)) return;
  let session;
  try {
    session = verifyAccessToken(token);
    if (session.id !== socket.userId) throw new Error('Account mismatch');
  } catch {
    return socket.emit('duel_result', {matchId, status:'unavailable'});
  }
  try {
    const row = await wallet.receipt(matchId, socket.userId, session);
    socket.emit('duel_result', {matchId, status: !row ? 'unknown' : row.payout === null ? 'pending' : 'closed',
      ...(row && { wager: row.wager, potWon: row.payout })});
  } catch (error) {
    logger.error('Unable to read duel result', error);
    socket.emit('duel_result', {matchId, status:'retry'});
  }
}

async function settle(match, result) {
  try {
    const winnerId = match[result]?.socket.userId || null;
    const paid = await wallet.settle(match.id, result === 'draw' ? 'draw' : 'win', winnerId);
    const roles = match.p2 ? ['p1', 'p2'] : ['p1'];
    const receipts = paid ? [] : await Promise.all(roles.map(role => wallet.receipt(match.id, match[role].socket.userId)));
    if (receipts.some(row => row && row.payout === null)) {
      // The hold has expired but the durable refund has not run yet.
      match.retry = setTimeout(() => settle(match, result), 5000);
      return;
    }
    for (const [index, role] of roles.entries()) {
      const p = match[role];
      const expected = result === 'draw' ? p.wager : result === role ? p.wager * 2 : 0;
      const actual = paid ? expected : receipts[index]?.payout;
      forget(p);
      if (actual === p.wager && match.cancelled) {
        p.socket.emit('queue_left', {refundedWager: p.wager});
      } else if (actual === expected) {
        io.to(p.socket.id).emit('game_over', {
          matchId: match.id, winner: result, isWinner: result === role, isDraw: result === 'draw',
          potWon: actual,
          wager: p.wager, myScore: match.scores[role], opScore: match.scores[role === 'p1' ? 'p2' : 'p1']
        });
      } else if (actual === p.wager) {
        p.socket.emit('game_over', {matchId: match.id, winner:'draw', isDraw:true, refunded:true, wager:p.wager, potWon:actual});
      } else {
        p.socket.emit('error', {message:'This match has closed. Refresh your wallet to see the final balance.'});
      }
    }
    matches.delete(match.id);
  } catch (error) {
    logger.error('Duel settlement will be retried', error);
    match.retry = setTimeout(() => settle(match, result), 5000);
  }
}

function _clearAllTimers() {
  clearInterval(recoveryTimer);
  for (const member of members.values()) clearTimeout(member.timer);
  for (const match of matches.values()) { stopTimers(match); clearTimeout(match.retry); }
  matches.clear();
  members.clear();
}

module.exports = { initializeSocket, _clearAllTimers };
