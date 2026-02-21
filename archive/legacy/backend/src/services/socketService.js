const socketIo = require('socket.io');
const WalletService = require('./walletService');

let io;
const duelQueue = []; // Simple array for MVP matchmaking: [{id: socketId, wager: 5}]
const activeDuels = new Map(); // matchId -> { p1, p2, p1Score, p2Score, questions, timeRemaining }

const initializeSocket = (server) => {
    io = socketIo(server, {
        cors: {
            origin: "*", // Allow all origins for MVP
            methods: ["GET", "POST"]
        }
    });

    io.on('connection', (socket) => {
        console.log('New client connected:', socket.id);

        // --- LOBBY LOGIC ---
        socket.on('join_queue', async ({ wager, userId }) => {
            console.log(`User ${socket.id} joining queue for ${wager} coins`);

            // 0. Mock UserID if missing (for simulator)
            const uId = userId || 1; // Default to 1 for MVP if not sent

            // 1. Validate Funds
            const hasFunds = await WalletService.sinkWager(uId, wager);
            if (!hasFunds) {
                socket.emit('error', { message: 'Insufficient funds' });
                return;
            }

            // 2. Check matchmaking
            const opponentIndex = duelQueue.findIndex(u => u.wager === wager && u.id !== socket.id);

            if (opponentIndex > -1) {
                // MATCH FOUND!
                const opponent = duelQueue.splice(opponentIndex, 1)[0];
                const matchId = `match_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;

                console.log(`Match creating: ${socket.id} vs ${opponent.id}`);

                // Create Match State
                activeDuels.set(matchId, {
                    p1: { id: socket.id, dbId: uId },
                    p2: { id: opponent.id, dbId: opponent.dbId },
                    p1Score: 0,
                    p2Score: 0,
                    wager: wager,
                    timeRemaining: 60,
                    questions: generateMockQuestions(), // TODO: Fetch from DB later
                    status: 'active'
                });

                // Notify Players
                io.to(socket.id).emit('match_found', { matchId, opponentId: opponent.id, role: 'p1' });
                io.to(opponent.id).emit('match_found', { matchId, opponentId: socket.id, role: 'p2' });

                // Start Timer
                startMatchTimer(matchId);

            } else {
                // NO MATCH -> WAIT
                duelQueue.push({ id: socket.id, dbId: uId, wager });
                socket.emit('queue_joined', { message: 'Waiting for opponent...' });
            }
        });

        // --- GAME LOGIC ---
        socket.on('submit_answer', ({ matchId, correct }) => {
            const match = activeDuels.get(matchId);
            if (!match || match.status !== 'active') return;

            // Check using socket.id against p1.id / p2.id
            if (socket.id === match.p1.id) {
                if (correct) match.p1Score++;
            } else if (socket.id === match.p2.id) {
                if (correct) match.p2Score++;
            }

            // Broadcast score update to BOTH players
            io.to(match.p1.id).emit('score_update', { p1: match.p1Score, p2: match.p2Score });
            io.to(match.p2.id).emit('score_update', { p1: match.p1Score, p2: match.p2Score });
        });

        socket.on('disconnect', () => {
            console.log('Client disconnected:', socket.id);
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

    io.to(match.p1.id).emit('game_over', { winner: winnerSocket, myScore: match.p1Score, opScore: match.p2Score });
    io.to(match.p2.id).emit('game_over', { winner: winnerSocket, myScore: match.p2Score, opScore: match.p1Score });

    console.log(`Match ${matchId} ended. Winner: ${winnerSocket}`);
    activeDuels.delete(matchId);
}

function handleDisconnect(socketId) {
    // Remove from queue
    const idx = duelQueue.findIndex(u => u.id === socketId);
    if (idx > -1) {
        // Refund if waiting in queue
        const user = duelQueue[idx];
        WalletService.refund(user.dbId, user.wager);
        duelQueue.splice(idx, 1);
    }

    // Forfeit active matches
    for (const [matchId, match] of activeDuels.entries()) {
        if (match.p1.id === socketId || match.p2.id === socketId) {
            const winner = (match.p1.id === socketId) ? match.p2 : match.p1;

            // AUTO WIN for survivor
            WalletService.awardPot(winner.dbId, match.wager * 2);

            io.to(winner.id).emit('opponent_disconnected', { win: true });
            activeDuels.delete(matchId); // Immediate cleanup on MVP
        }
    }
}

function generateMockQuestions() {
    return [
        { q: "What is the powerhouse of the cell?", a: "Mitochondria" },
        { q: "Normal HR range?", a: "60-100" },
        { q: "Capital of France?", a: "Paris" } // Placeholder
    ];
}

module.exports = { initializeSocket };
