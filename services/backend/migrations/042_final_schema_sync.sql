-- ------------------------------------------------------------------------------
-- 🛠️ Migration 042: Final Schema Synchronization
-- Purpose: Aligns the database with backend controller expectations (fixes 500 errors).
-- ------------------------------------------------------------------------------

-- 1. Standardize Questions 'active' column
-- Some controllers use 'active', while others used 'is_active'.
DO $$ 
BEGIN 
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'questions' AND column_name = 'is_active') THEN
        ALTER TABLE questions RENAME COLUMN is_active TO active;
    END IF;
END $$;

-- 2. Add 'description' to Topics
-- topicController.js expects this column.
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'topics' AND column_name = 'description') THEN
        ALTER TABLE topics ADD COLUMN description TEXT;
    END IF;
END $$;

-- 3. Ensure 'user_activity' table matches expectations
-- The '/activity' endpoint often references a log of recent actions.
CREATE TABLE IF NOT EXISTS user_activity (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(255) NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Ensure indexes for performance
CREATE INDEX IF NOT EXISTS idx_questions_active ON questions(active);
CREATE INDEX IF NOT EXISTS idx_user_activity_user ON user_activity(user_id);
