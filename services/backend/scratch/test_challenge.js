const db = require('../src/config/db');
const ls = require('../src/services/learningService');

async function test() {
    try {
        console.log('--- Testing Question Selection ---');
        const topic = 'cardiovascular-system';
        const userId = 1; // Existing user in DB with progress

        console.log(`\nTesting user ${userId} for topic: ${topic}`);
        const challenge = await ls.getChallenge(userId, topic);

        if (challenge) {
            console.log('✅ Found Question!');
            console.log('ID:', challenge.id);
            console.log('Selection Reason:', challenge.selectionReason);
            console.log('Bloom Level:', challenge.bloom_level);
        } else {
            console.log('❌ No question found (This might be expected if DB is empty, but we verified it has 5000)');
        }

        console.log('\n--- Testing Answer Submission ---');
        if (challenge) {
            const res = await ls.resolveResponse(userId, topic, challenge.id, true, 4);
            console.log('✅ Response resolved successfully!');
            console.log('New Mastery:', res.mastery_score);
            console.log('New Bloom Level:', res.current_bloom_level);
            console.log('SRS Interval:', res.srs.interval);
        }

    } catch (e) {
        console.error('❌ TEST FAILED with error:');
        console.error(e);
    } finally {
        process.exit();
    }
}

test();
