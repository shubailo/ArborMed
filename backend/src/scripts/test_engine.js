const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });
const db = require('../config/db');
const engine = require('../services/adaptiveEngine');

async function testEngine() {
    // Get a real user ID from context or DB
    const userRes = await db.query('SELECT id FROM users LIMIT 1');
    const userId = userRes.rows[0]?.id;

    if (!userId) {
        console.error('No users found to test with.');
        process.exit(1);
    }

    // Get a topic with questions
    const topicRes = await db.query(`
    SELECT t.slug, COUNT(q.id) as q_count 
    FROM topics t 
    JOIN questions q ON q.topic_id = t.id 
    WHERE q.active = TRUE 
    GROUP BY t.slug 
    ORDER BY q_count DESC 
    LIMIT 5
  `);

    console.log(`🧪 Testing AdaptiveEngine for User ID: ${userId}\n`);

    for (const topic of topicRes.rows) {
        console.log(`Checking Topic: ${topic.slug} (Active Questions: ${topic.q_count})`);
        try {
            const question = await engine.getNextQuestion(userId, topic.slug);
            if (question) {
                console.log(`✅ Returned Question ID: ${question.id}`);
                console.log(`   Text: ${question.question_text_en?.substring(0, 50)}...`);
            } else {
                console.log('❌ NO QUESTION RETURNED');
            }
        } catch (err) {
            console.error(`💥 Error for topic ${topic.slug}:`, err.message);
        }
        console.log('---');
    }

    process.exit(0);
}

testEngine();
