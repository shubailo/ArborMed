const db = require('../config/db');
const logger = require('../utils/logger');

// In-memory state for active wards
// roomId -> { users: Set(socketId), hostId: userId, currentCase: null, votes: Map(socketId -> answerId), state: 'LOBBY' | 'PLAYING' | 'SUMMARY' }
const activeWards = new Map();

// Map to track socketId -> roomId for quick disconnect handling
const socketToRoom = new Map();

/**
 * Generates a random 6-character alphanumeric code
 */
function generateRoomCode() {
  return Math.random().toString(36).substring(2, 8).toUpperCase();
}

/**
 * Initializes Ward-specific socket event listeners.
 * Assumes the socket is already authenticated and has `socket.userId`.
 */
const initializeWardSocket = (io, socket) => {

  // 1. Create a new Ward
  socket.on('ward_create', async ({ wardName }) => {
    try {
      const uId = socket.userId;
      const code = generateRoomCode();

      // Save to database
      const wardRes = await db.query(
        'INSERT INTO wards (code, name, host_id) VALUES ($1, $2, $3) RETURNING id',
        [code, wardName || 'My Study Ward', uId]
      );
      const wardId = wardRes.rows[0].id;

      // Initialize in-memory state
      activeWards.set(code, {
        dbId: wardId,
        users: new Set([socket.id]),
        hostId: uId,
        currentCase: null,
        votes: new Map(),
        state: 'LOBBY',
      });

      socketToRoom.set(socket.id, code);
      socket.join(code);

      socket.emit('ward_created', { code, wardId, name: wardName });
      logger.info(`Ward ${code} created by user ${uId}`);
    } catch (err) {
      logger.error('Error creating ward:', err);
      socket.emit('ward_error', { message: 'Failed to create Ward.' });
    }
  });

  // 2. Join an existing Ward
  socket.on('ward_join', async ({ code }) => {
    try {
      const normalizedCode = code.toUpperCase();
      const uId = socket.userId;
      const wardState = activeWards.get(normalizedCode);

      if (!wardState) {
        socket.emit('ward_error', { message: 'Ward not found or inactive.' });
        return;
      }

      // Add to state and join socket room
      wardState.users.add(socket.id);
      socketToRoom.set(socket.id, normalizedCode);
      socket.join(normalizedCode);

      // (Optional) Add user to ward_members table for persistence
      await db.query(
        'INSERT INTO ward_members (ward_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
        [wardState.dbId, uId]
      );

      // Broadcast update to everyone in the room
      io.to(normalizedCode).emit('ward_updated', {
        usersCount: wardState.users.size,
        state: wardState.state
      });

      socket.emit('ward_joined', { code: normalizedCode, message: 'Successfully joined Ward.' });
      logger.info(`User ${uId} joined Ward ${normalizedCode}`);
    } catch (err) {
      logger.error('Error joining ward:', err);
      socket.emit('ward_error', { message: 'Failed to join Ward.' });
    }
  });

  // 3. Start Round (Host only)
  socket.on('ward_start_round', async ({ code }) => {
    const wardState = activeWards.get(code);
    if (!wardState) return;

    if (wardState.hostId !== socket.userId) {
      socket.emit('ward_error', { message: 'Only the Attending (Host) can start a round.' });
      return;
    }

    try {
      // Mock fetching a Level 4 question
      const qRes = await db.query(
        'SELECT id, text, options FROM questions WHERE bloom_level >= 3 ORDER BY RANDOM() LIMIT 1'
      );

      if (qRes.rows.length === 0) {
        socket.emit('ward_error', { message: 'No suitable clinical cases found.' });
        return;
      }

      wardState.state = 'PLAYING';
      wardState.currentCase = qRes.rows[0];
      wardState.votes.clear();

      io.to(code).emit('ward_round_started', {
        question: {
          id: wardState.currentCase.id,
          text: wardState.currentCase.text,
          options: wardState.currentCase.options
        }
      });
      logger.info(`Ward ${code} started a round with question ${wardState.currentCase.id}`);
    } catch (err) {
      logger.error('Error starting ward round:', err);
    }
  });

  // 4. Submit Vote
  socket.on('ward_submit_vote', ({ code, answer }) => {
    const wardState = activeWards.get(code);
    if (!wardState || wardState.state !== 'PLAYING') return;

    wardState.votes.set(socket.id, answer);

    // Broadcast vote progress (without revealing answers)
    io.to(code).emit('ward_vote_update', {
      votesCast: wardState.votes.size,
      totalUsers: wardState.users.size
    });

    // Check if everyone has voted
    if (wardState.votes.size === wardState.users.size) {
      // End the round
      handleRoundEnd(io, code, wardState);
    }
  });

  // 5. Handle explicit leave
  socket.on('ward_leave', () => {
    handleDisconnect(io, socket);
  });
};

/**
 * Handles the logic when a round finishes (all votes in).
 */
async function handleRoundEnd(io, code, wardState) {
  try {
    wardState.state = 'SUMMARY';

    // Fetch the correct answer to verify
    const qRes = await db.query(
      'SELECT correct_answer FROM questions WHERE id = $1',
      [wardState.currentCase.id]
    );
    const correctAnswer = qRes.rows[0].correct_answer;

    // Tally votes
    const voteCounts = {};
    let correctVotes = 0;

    for (const answer of wardState.votes.values()) {
      voteCounts[answer] = (voteCounts[answer] || 0) + 1;
      if (answer === correctAnswer) correctVotes++;
    }

    // Determine consensus
    let consensusAnswer = null;
    let maxVotes = 0;
    for (const [ans, count] of Object.entries(voteCounts)) {
      if (count > maxVotes) {
        maxVotes = count;
        consensusAnswer = ans;
      }
    }

    const isConsensusCorrect = consensusAnswer === correctAnswer;

    io.to(code).emit('ward_round_ended', {
      correctAnswer,
      consensusAnswer,
      isConsensusCorrect,
      voteDistribution: voteCounts,
      correctVotes,
      totalVotes: wardState.votes.size
    });

    logger.info(`Ward ${code} ended round. Correct consensus? ${isConsensusCorrect}`);
  } catch(err) {
    logger.error('Error ending ward round', err);
  }
}

/**
 * Handles cleanup when a socket disconnects.
 * Exported so the main socketService can call it on 'disconnect'.
 */
const handleDisconnect = (io, socket) => {
  const code = socketToRoom.get(socket.id);
  if (!code) return;

  const wardState = activeWards.get(code);
  if (wardState) {
    wardState.users.delete(socket.id);
    wardState.votes.delete(socket.id);

    socket.leave(code);
    socketToRoom.delete(socket.id);

    if (wardState.users.size === 0) {
      // Ward is empty, clean it up
      activeWards.delete(code);
      logger.info(`Ward ${code} is empty and has been closed.`);

      // Update DB
      db.query('UPDATE wards SET is_active = false WHERE id = $1', [wardState.dbId]).catch(e => logger.error(e));
    } else {
      // Notify remaining users
      io.to(code).emit('ward_updated', {
        usersCount: wardState.users.size,
        state: wardState.state
      });

      // Re-check voting criteria if someone drops while playing
      if (wardState.state === 'PLAYING' && wardState.votes.size === wardState.users.size) {
         handleRoundEnd(io, code, wardState);
      }
    }
  }
};

module.exports = {
  initializeWardSocket,
  handleDisconnect
};
