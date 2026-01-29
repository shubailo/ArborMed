const db = require('./src/config/db');

async function migrate() {
    try {
        console.log('🚧 Starting SRS Migration...');

        // 1. Create table `user_question_progress`
        await db.query(`
      CREATE TABLE IF NOT EXISTS user_question_progress (
        user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        question_id INT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
        box INT DEFAULT 0, -- 0=New, 1-5=Leitner Boxes
        next_review_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        PRIMARY KEY (user_id, question_id)
      );
    `);
        console.log('✅ Created table: user_question_progress');

        // 2. Create index for fast retrieval of due reviews
        await db.query(`
      CREATE INDEX IF NOT EXISTS idx_srs_next_review ON user_question_progress(user_id, next_review_at);
    `);
        console.log('✅ Created index: idx_srs_next_review');

        console.log('🎉 SRS Migration Complete!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Migration Failed:', err);
        process.exit(1);
    }
}

migrate();
