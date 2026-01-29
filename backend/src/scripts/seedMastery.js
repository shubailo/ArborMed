const db = require('../config/db');

async function seedMastery() {
    try {
        console.log('Seeding user mastery...');

        // 1. Get all users
        const usersRes = await db.query('SELECT id FROM users');
        const users = usersRes.rows;

        if (users.length === 0) {
            console.log('No users found. Skipping mastery seed.');
            return;
        }

        // 2. Get all topics
        const topicsRes = await db.query('SELECT slug, name FROM topics');
        const topics = topicsRes.rows;

        if (topics.length === 0) {
            console.log('No topics found. Please run regular seed logic first.');
            return;
        }

        // 3. Insert mastery records
        for (const user of users) {
            for (const topic of topics) {
                await db.query(`
          INSERT INTO user_mastery (user_id, subject, proficiency, level)
          VALUES ($1, $2, 0, 1)
          ON CONFLICT (user_id, subject) DO NOTHING
        `, [user.id, topic.slug]); // Use slug as the subject identifier
            }
            console.log(`Initialized mastery for User ID ${user.id} covering ${topics.length} subjects.`);
        }

        console.log('Mastery seeding complete.');
    } catch (err) {
        console.error('Mastery seeding failed:', err);
    } finally {
        await db.pool.end();
    }
}

seedMastery();
