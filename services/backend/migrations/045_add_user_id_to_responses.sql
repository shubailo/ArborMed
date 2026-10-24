-- Migration: Add user_id directly to responses table and backfill from quiz_sessions
ALTER TABLE responses ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id);

-- Backfill user_id from quiz_sessions for existing responses
UPDATE responses r
SET user_id = qs.user_id
FROM quiz_sessions qs
WHERE r.session_id = qs.id AND r.user_id IS NULL;

-- Index for user response queries, analytics, and fail-down lookup
CREATE INDEX IF NOT EXISTS idx_responses_user_created ON responses (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_responses_user_question ON responses (user_id, question_id);
