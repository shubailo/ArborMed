
-- 036_question_reports_simple.sql

-- 1. Create Question Reports Table
CREATE TABLE IF NOT EXISTS question_reports (
    id SERIAL PRIMARY KEY,
    question_id INTEGER REFERENCES questions(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    reason_category VARCHAR(50) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Index for fast lookup by question
CREATE INDEX IF NOT EXISTS idx_question_reports_question_id ON question_reports(question_id);

-- 3. Index for fast lookup by user
CREATE INDEX IF NOT EXISTS idx_question_reports_user_id ON question_reports(user_id);
