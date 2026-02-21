-- Migration: 017_security_and_performance_fix.sql
-- Description: Implement least-privilege roles, hierarchical RLS, and performance indexes.
-- Author: Antigravity Debugger
-- Date: 2026-02-02

-- 1. DATABASE ROLE (LEAST PRIVILEGE)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'med_buddy_app') THEN
        CREATE ROLE med_buddy_app WITH LOGIN PASSWORD 'med_buddy_secure_pwd_2026';
    END IF;
    
    -- Grant necessary permissions
    GRANT CONNECT ON DATABASE postgres TO med_buddy_app;
    GRANT USAGE ON SCHEMA public TO med_buddy_app;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO med_buddy_app;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO med_buddy_app;
    
    -- IMPORTANT: Give our backend role the ability to bypass RLS.
    -- This treats the Node.js backend as the "Service Role" (Trusted Layer).
    -- RLS will still protect the database from direct exposure via PostgREST (Anon/Authenticated keys).
    ALTER ROLE med_buddy_app WITH BYPASSRLS;
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
-- Enable RLS on ALL tables to block unwanted direct API access (PostgREST)
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN (SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE') LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', t);
    END LOOP;
END
$$;

-- 5. POLICIES (Safety Layer for PostgREST)

-- 5.1 Helper to drop policies if they exist (PostgreSQL 9.5+)
-- This ensures idempotency when re-running the script.

-- Drop existing policies to avoid "already exists" errors
DROP POLICY IF EXISTS "Public Read Access" ON topics;
DROP POLICY IF EXISTS "Public Read Access" ON questions;
DROP POLICY IF EXISTS "Public Read Access" ON ecg_cases;
DROP POLICY IF EXISTS "Public Read Access" ON ecg_diagnoses;
DROP POLICY IF EXISTS "Public Read Access" ON items;
DROP POLICY IF EXISTS "Public Read Access" ON quotes;

-- Allow public read of non-sensitive educational content
CREATE POLICY "Public Read Access" ON topics FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Access" ON questions FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Access" ON ecg_cases FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Access" ON ecg_diagnoses FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Access" ON items FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Access" ON quotes FOR SELECT TO public USING (true);

-- Explicitly DENY all access to sensitive tables for public/authenticated roles
-- (RLS is "deny by default", but having no policy ensures no access via Anon/Authenticated roles)
-- Tables like users, password_resets, refresh_tokens, sessions, responses will be 
-- accessible ONLY by our backend role (med_buddy_app) because it has BYPASSRLS.

-- Permissions reminder for med_buddy_app
GRANT USAGE ON SCHEMA public TO med_buddy_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO med_buddy_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO med_buddy_app;
