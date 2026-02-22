const db = require('../config/db');

const migrate = async () => {
    try {
        console.log('Starting Progress Counter Migration...');

        // Add level_correct_count to user_topic_progress if it doesn't exist
        await db.query(`
            ALTER TABLE user_topic_progress 
            ADD COLUMN IF NOT EXISTS level_correct_count INT DEFAULT 0;
        `);
        console.log('✅ Added level_correct_count column.');

        console.log('Migration Complete.');
        process.exit();
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
};

migrate();
