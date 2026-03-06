-- Upgrade User Question Progress to support SM-2 Spaced Repetition
ALTER TABLE user_question_progress 
ADD COLUMN IF NOT EXISTS easiness_factor DECIMAL DEFAULT 2.5,
ADD COLUMN IF NOT EXISTS interval_days INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS repetition_count INTEGER DEFAULT 0;

-- Upgrade Responses to persist SM-2 session state for analytics
ALTER TABLE responses
ADD COLUMN IF NOT EXISTS quality INTEGER,
ADD COLUMN IF NOT EXISTS easiness_factor DECIMAL,
ADD COLUMN IF NOT EXISTS interval_days INTEGER,
ADD COLUMN IF NOT EXISTS selection_reason TEXT;

-- Upgrade User Topic Progress for weighted mastery and stability tracking
ALTER TABLE user_topic_progress
ADD COLUMN IF NOT EXISTS unlocked_bloom_level INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS questions_mastered INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS stability DECIMAL DEFAULT 1.0,
ADD COLUMN IF NOT EXISTS retention_score INTEGER DEFAULT 100,
ADD COLUMN IF NOT EXISTS ef_modifier DECIMAL DEFAULT 1.0;

-- Index for SRS performance
CREATE INDEX IF NOT EXISTS idx_uqp_next_review ON user_question_progress (user_id, next_review_at);

-- Update existing records to reasonable defaults
UPDATE user_topic_progress SET unlocked_bloom_level = current_bloom_level WHERE unlocked_bloom_level IS NULL;
