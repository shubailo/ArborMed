-- 035_ensure_adaptive_learning.sql

-- 1. Ensure the table exists
CREATE TABLE IF NOT EXISTS user_topic_progress (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    topic_slug VARCHAR(100) NOT NULL,
    current_bloom_level INTEGER DEFAULT 1,
    current_streak INTEGER DEFAULT 0,
    consecutive_wrong INTEGER DEFAULT 0,
    total_answered INTEGER DEFAULT 0,
    correct_answered INTEGER DEFAULT 0,
    mastery_score INTEGER DEFAULT 0,
    last_studied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, topic_slug)
);

-- 2. Ensure all columns needed by AdaptiveEngine exist
DO $$
BEGIN
    -- level_correct_count
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_topic_progress' AND column_name='level_correct_count') THEN
        ALTER TABLE user_topic_progress ADD COLUMN level_correct_count INTEGER DEFAULT 0;
    END IF;

    -- unlocked_bloom_level
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_topic_progress' AND column_name='unlocked_bloom_level') THEN
        ALTER TABLE user_topic_progress ADD COLUMN unlocked_bloom_level INTEGER DEFAULT 1;
    END IF;

    -- questions_mastered
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_topic_progress' AND column_name='questions_mastered') THEN
        ALTER TABLE user_topic_progress ADD COLUMN questions_mastered INTEGER DEFAULT 0;
    END IF;
    
    -- retention_score (Re-check to be safe)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_topic_progress' AND column_name='retention_score') THEN
        ALTER TABLE user_topic_progress ADD COLUMN retention_score FLOAT DEFAULT 0;
    END IF;

    -- stability
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_topic_progress' AND column_name='stability') THEN
        ALTER TABLE user_topic_progress ADD COLUMN stability FLOAT DEFAULT 0;
    END IF;

    -- last_reviewed_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_topic_progress' AND column_name='last_reviewed_at') THEN
        ALTER TABLE user_topic_progress ADD COLUMN last_reviewed_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;
