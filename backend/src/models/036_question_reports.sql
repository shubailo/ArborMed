
-- 036_question_reports.sql

-- 1. Create Question Reports Table
CREATE TABLE IF NOT EXISTS question_reports (
    id SERIAL PRIMARY KEY,
    question_id INTEGER REFERENCES questions(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    reason_category VARCHAR(50) NOT NULL, -- 'wrong_answer', 'typo', 'confusing', 'technical'
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'resolved', 'ignored'
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Index for fast lookup by question (Admin View)
CREATE INDEX IF NOT EXISTS idx_question_reports_question_id ON question_reports(question_id);

-- 3. Index for fast lookup by user (My Reports)
CREATE INDEX IF NOT EXISTS idx_question_reports_user_id ON question_reports(user_id);

-- 4. RLS Policies
ALTER TABLE question_reports ENABLE ROW LEVEL SECURITY;

-- Student: Can create reports, view own reports
CREATE POLICY "Students create reports" ON question_reports 
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id::text);

CREATE POLICY "Students view own reports" ON question_reports 
    FOR SELECT TO authenticated USING (auth.uid() = user_id::text);

-- Admin: Can view all, update status
CREATE POLICY "Admins full access reports" ON question_reports 
    FOR ALL TO authenticated USING (
        EXISTS (SELECT 1 FROM users WHERE id::text = auth.uid() AND role = 'admin')
    );
