const axios = require('axios');
const db = require('../config/db');

// Config
const API_URL = 'http://localhost:3000';
let token = '';
let sessionId = 0;
let questionId = 0;
let correctAnswer = '';

async function runTest() {
    try {
        console.log('--- STARTING GAMIFICATION TEST ---');

        // 1. Register logic
        console.log('1. Registering/Logging in...');
        const email = `testuser_${Date.now()}@example.com`;
        const registerRes = await axios.post(`${API_URL}/auth/register`, {
            email: email,
            password: 'password123',
            name: 'TestUser'
        });
        token = registerRes.data.token;
        console.log(`Registered ${email}. Token acquired.`);

        // 2. Start Quiz Session
        console.log('2. Starting Quiz Session...');
        const sessionRes = await axios.post(`${API_URL}/quiz/start`, {}, {
            headers: { Authorization: `Bearer ${token}` }
        });
        sessionId = sessionRes.data.id;
        console.log(`Session started. ID: ${sessionId}`);

        // 3. Get Question (Cardiovascular)
        console.log('3. Fetching Question...');
        const qRes = await axios.get(`${API_URL}/quiz/next?topic=cardiovascular`, {
            headers: { Authorization: `Bearer ${token}` }
        });
        questionId = qRes.data.id;
        console.log(`Question fetched. ID: ${questionId}`);

        // Note: In a real test, we'd need to know the correct answer. 
        // For this test, I'll cheat and query the DB for the correct answer to ensure a "Correct" submission.
        const dbQ = await db.query('SELECT correct_answer FROM questions WHERE id = $1', [questionId]);
        correctAnswer = dbQ.rows[0].correct_answer;
        console.log(`(Cheat) Correct Answer is: ${correctAnswer}`);

        // 4. Submit Correct Answer (Check Streak/Coins)
        console.log('4. Submitting Correct Answer...');
        const submitRes = await axios.post(`${API_URL}/quiz/answer`, {
            sessionId: sessionId,
            questionId: questionId,
            userAnswer: correctAnswer,
            responseTimeMs: 2000
        }, {
            headers: { Authorization: `Bearer ${token}` }
        });

        console.log('Submission Result:', submitRes.data);

        if (submitRes.data.streak > 0 && submitRes.data.coinsEarned > 0) {
            console.log('✅ SUCCESS: Streak increased and coins earned.');
        } else {
            console.log('❌ FAILURE: Streak or coins logic failed.');
        }

        console.log('--- TEST COMPLETE ---');

    } catch (e) {
        console.error('TEST FAILED:', e.response ? e.response.data : e.message);
    } finally {
        await db.pool.end();
    }
}

runTest();
