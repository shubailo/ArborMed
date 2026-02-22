const db = require('../config/db');

const migrateBloom = async () => {
    try {
        console.log('Starting Bloom Migration...');

        console.log(`Connecting to ${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`);

        // 1. Add Bloom Level (and Difficulty if missing) to Questions
        await db.query(`
            ALTER TABLE questions 
            ADD COLUMN difficulty INT DEFAULT 1,
            ADD COLUMN bloom_level INT DEFAULT 1;
        `);
        console.log('✅ Added bloom_level/difficulty into questions.');

        // 2. Create User Topic Progress Table
        await db.query(`
            CREATE TABLE IF NOT EXISTS user_topic_progress (
                id SERIAL PRIMARY KEY,
                user_id INT REFERENCES users(id) ON DELETE CASCADE,
                topic_slug VARCHAR(50) NOT NULL,
                current_bloom_level INT DEFAULT 1,
                current_streak INT DEFAULT 0,
                consecutive_wrong INT DEFAULT 0,
                total_answered INT DEFAULT 0,
                UNIQUE(user_id, topic_slug)
            );
        `);
        console.log('✅ Created user_topic_progress table.');

        console.log('Bloom Migration Complete.');
        process.exit();
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
};

migrateBloom();
