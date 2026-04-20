-- Implementation of the Pathophysiology Learning Graph (Nexus & Prerequisites)
-- This migration enables the "Diagnostic Fail-Down" and "Mastery Propagation" logic.

-- 1. Question Prerequisites Table (Option A)
-- Maps Bloom Level 3/4 questions to their fundamental building blocks (Bloom 1/2).
CREATE TABLE IF NOT EXISTS question_prerequisites (
    id SERIAL PRIMARY KEY,
    question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    prerequisite_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    CHECK (question_id != prerequisite_id),
    -- Ensure a question isn't its own prerequisite
    UNIQUE(question_id, prerequisite_id)
);

-- 2. Topic Nexus Table (Option B)
-- Defines horizontal "Common Logic" links between seemingly different organ systems.
CREATE TABLE IF NOT EXISTS topic_nexus (
    id SERIAL PRIMARY KEY,
    topic_a_id INTEGER NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    topic_b_id INTEGER NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    correlation_strength DECIMAL DEFAULT 1.0, -- Default to full correlation
    CHECK (topic_a_id < topic_b_id), -- Prevent duplicate (A,B) and (B,A) entries
    UNIQUE(topic_a_id, topic_b_id)
);

-- 3. Adaptive Tracking Expansion
-- Add 'current_nexus_mastery' to user progression
ALTER TABLE user_topic_progress 
ADD COLUMN IF NOT EXISTS predictive_mastery_boost DECIMAL DEFAULT 0.0;

-- 4. Initial Indexing for Engine Performance
CREATE INDEX IF NOT EXISTS idx_qp_source ON question_prerequisites(question_id);
CREATE INDEX IF NOT EXISTS idx_tn_source ON topic_nexus(topic_a_id);
CREATE INDEX IF NOT EXISTS idx_tn_target ON topic_nexus(topic_b_id);

COMMENT ON TABLE question_prerequisites IS 'Stores vertical dependencies between foundational facts and complex clinical mechanisms.';
COMMENT ON TABLE topic_nexus IS 'Stores horizontal logical connections between organ systems (e.g., Renal <-> Cardiovascular).';
