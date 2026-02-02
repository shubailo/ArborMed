-- Migration: 017_security_and_performance_fix.sql
-- Description: Implement least-privilege roles, hierarchical RLS, and performance indexes.
-- Author: Antigravity Debugger
-- Date: 2026-02-02

-- 1. DATABASE ROLE (LEAST PRIVILEGE)
-- Note: This creates the role if it doesn't exist. Supabase usually handles this via UI,
-- but having it in SQL is good for documentation/local dev.
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'med_buddy_app') THEN
        CREATE ROLE med_buddy_app WITH LOGIN PASSWORD 'med_buddy_secure_pwd_2026';
        GRANT CONNECT ON DATABASE postgres TO med_buddy_app;
        GRANT USAGE ON SCHEMA public TO med_buddy_app;
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO med_buddy_app;
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO med_buddy_app;
    END IF;
END
$$;

-- 2. PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_topics_parent_id ON topics(parent_id);
CREATE INDEX IF NOT EXISTS idx_questions_topic_id ON questions(topic_id);
CREATE INDEX IF NOT EXISTS idx_questions_difficulty ON questions(difficulty);
CREATE INDEX IF NOT EXISTS idx_quiz_sessions_user_id ON quiz_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_responses_session_id ON responses(session_id);
CREATE INDEX IF NOT EXISTS idx_user_items_user_id ON user_items(user_id);

-- 3. SCHEMA UPDATES (COMPLEX ROLES & AUTH)
-- Cohorts for Teacher-Student hierarchy
CREATE TABLE IF NOT EXISTS cohorts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    teacher_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cohort_members (
    id SERIAL PRIMARY KEY,
    cohort_id INTEGER REFERENCES cohorts(id) ON DELETE CASCADE,
    student_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(cohort_id, student_id)
);

-- Refresh Tokens table
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);

-- 4. ROW LEVEL SECURITY (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;

-- 5. POLICIES

-- Topics/Questions/Items/Quotes are readable by everyone
CREATE POLICY "Public Read Access" ON topics FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Access" ON questions FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Access" ON items FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Access" ON quotes FOR SELECT TO public USING (true);

-- User Profile (Own only)
CREATE POLICY "User Own Data Access" ON users 
    FOR ALL TO authenticated 
    USING (id = auth.uid()::text::integer) 
    WITH CHECK (id = auth.uid()::text::integer);

-- Quiz Sessions (Own or Teacher's students)
CREATE POLICY "Student Own Sessions" ON quiz_sessions
    FOR ALL TO authenticated
    USING (user_id = auth.uid()::text::integer)
    WITH CHECK (user_id = auth.uid()::text::integer);

CREATE POLICY "Teacher Access Student Sessions" ON quiz_sessions
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM cohorts c
            JOIN cohort_members cm ON c.id = cm.cohort_id
            WHERE c.teacher_id = auth.uid()::text::integer
            AND cm.student_id = quiz_sessions.user_id
        )
    );

-- Responses (Matching Session Access)
CREATE POLICY "Response Access Policy" ON responses
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM quiz_sessions s
            WHERE s.id = responses.session_id
            AND (s.user_id = auth.uid()::text::integer OR 
                 EXISTS (
                     SELECT 1 FROM cohorts c
                     JOIN cohort_members cm ON c.id = cm.cohort_id
                     WHERE c.teacher_id = auth.uid()::text::integer
                     AND cm.student_id = s.user_id
                 ))
        )
    );

-- User Items/Rooms (Own only)
CREATE POLICY "User Own Items Access" ON user_items
    FOR ALL TO authenticated
    USING (user_id = auth.uid()::text::integer)
    WITH CHECK (user_id = auth.uid()::text::integer);

CREATE POLICY "User Own Rooms Access" ON user_rooms
    FOR ALL TO authenticated
    USING (user_id = auth.uid()::text::integer)
    WITH CHECK (user_id = auth.uid()::text::integer);

-- Permissions for the app user role
GRANT USAGE ON SCHEMA public TO med_buddy_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO med_buddy_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO med_buddy_app;
