-- Upgrade for Pedagogical Engine (SM-2 & Analytics)

-- 1. Responses Table: Capture SM-2 inputs and selection reason
ALTER TABLE responses
ADD COLUMN IF NOT EXISTS quality INT DEFAULT NULL CHECK (quality BETWEEN 0 AND 5),
ADD COLUMN IF NOT EXISTS easiness_factor FLOAT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS interval_days FLOAT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS selection_reason TEXT DEFAULT NULL;

-- 2. User Question Progress: Store SM-2 State
ALTER TABLE user_question_progress
ADD COLUMN IF NOT EXISTS easiness_factor FLOAT DEFAULT 2.5,
ADD COLUMN IF NOT EXISTS interval_days FLOAT DEFAULT 0;
