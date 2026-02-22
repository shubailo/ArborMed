-- Migration 020: Supabase Security & Performance Fixes (COMPLETE)
-- Description: Enables RLS on public tables, sets up RLS policies with correct column names, 
--              applies performance optimizations, fixes type casting, and adds missing indexes.

-- 1. Fix admin_question_stats view to be SECURITY INVOKER
DROP VIEW IF EXISTS admin_question_stats;
CREATE VIEW admin_question_stats WITH (security_invoker = true) AS
SELECT 
    u.id as admin_id,
    u.email,
    u.assigned_subject_id,
    t.name_en as assigned_subject_name,
    COUNT(q.id) as total_questions_created,
    COUNT(CASE WHEN q.active = TRUE THEN 1 END) as active_questions
FROM users u
LEFT JOIN questions q ON q.created_by = u.id
LEFT JOIN topics t ON t.id = u.assigned_subject_id
WHERE u.role = 'admin'
GROUP BY u.id, u.email, u.assigned_subject_id, t.name_en;

GRANT SELECT ON admin_question_stats TO med_buddy_app;
GRANT SELECT ON admin_question_stats TO authenticated;

-- 2. Enable RLS on all identified tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE cohort_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultation_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE password_resets ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_mastery ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_question_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_topic_progress ENABLE ROW LEVEL SECURITY;

-- 3. Grant bypass to backend service user
DO $$ 
BEGIN 
  IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'med_buddy_app') THEN
    ALTER ROLE med_buddy_app BYPASSRLS;
  END IF;
END $$;

-- 4. PERFORMANCE & TYPE-SAFE RLS Policies
-- We cast both auth.uid() and IDs to TEXT to ensure equality works across types (UUID vs INT)
-- and wrap in (SELECT ...) for performance.

-- Users: User Own Data Access
DROP POLICY IF EXISTS "User Own Data Access" ON users;
CREATE POLICY "User Own Data Access" ON users 
    FOR ALL TO authenticated USING ((SELECT auth.uid())::text = id::text);

-- Quiz Sessions: Student Own Sessions
DROP POLICY IF EXISTS "Student Own Sessions" ON quiz_sessions;
CREATE POLICY "Student Own Sessions" ON quiz_sessions 
    FOR SELECT TO authenticated USING (user_id::text = (SELECT auth.uid())::text);

-- Quiz Sessions: Teacher Access Student Sessions
DROP POLICY IF EXISTS "Teacher Access Student Sessions" ON quiz_sessions;
CREATE POLICY "Teacher Access Student Sessions" ON quiz_sessions 
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id::text = (SELECT auth.uid())::text AND role = 'admin'
        )
    );

-- Responses: Response Access Policy
DROP POLICY IF EXISTS "Response Access Policy" ON responses;
CREATE POLICY "Response Access Policy" ON responses 
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM quiz_sessions 
            WHERE id = responses.session_id AND user_id::text = (SELECT auth.uid())::text
        )
    );

-- User Items: User Own Items Access
DROP POLICY IF EXISTS "User Own Items Access" ON user_items;
CREATE POLICY "User Own Items Access" ON user_items 
    FOR SELECT TO authenticated USING (user_id::text = (SELECT auth.uid())::text);

-- User Rooms: User Own Rooms Access
DROP POLICY IF EXISTS "User Own Rooms Access" ON user_rooms;
CREATE POLICY "User Own Rooms Access" ON user_rooms 
    FOR SELECT TO authenticated USING (user_id::text = (SELECT auth.uid())::text);

-- Notifications: uses 'user_id'
DROP POLICY IF EXISTS select_own_notifications ON notifications;
CREATE POLICY select_own_notifications ON notifications 
    FOR SELECT TO authenticated USING (user_id::text = (SELECT auth.uid())::text);

-- Friendships: users can see their own
DROP POLICY IF EXISTS select_own_friendships ON friendships;
CREATE POLICY select_own_friendships ON friendships 
    FOR SELECT TO authenticated USING (
        requester_id::text = (SELECT auth.uid())::text OR receiver_id::text = (SELECT auth.uid())::text
    );

-- Mastery: uses 'user_id'
DROP POLICY IF EXISTS select_own_mastery ON user_mastery;
CREATE POLICY select_own_mastery ON user_mastery 
    FOR SELECT TO authenticated USING (user_id::text = (SELECT auth.uid())::text);

-- Consultation Notes
DROP POLICY IF EXISTS select_own_consultation_notes ON consultation_notes;
CREATE POLICY select_own_consultation_notes ON consultation_notes 
    FOR SELECT TO authenticated USING (
        author_id::text = (SELECT auth.uid())::text OR target_user_id::text = (SELECT auth.uid())::text
    );

-- Cohort Members
DROP POLICY IF EXISTS select_own_cohort_membership ON cohort_members;
CREATE POLICY select_own_cohort_membership ON cohort_members 
    FOR SELECT TO authenticated USING (student_id::text = (SELECT auth.uid())::text);

-- Progress
DROP POLICY IF EXISTS select_own_question_progress ON user_question_progress;
CREATE POLICY select_own_question_progress ON user_question_progress 
    FOR SELECT TO authenticated USING (user_id::text = (SELECT auth.uid())::text);

DROP POLICY IF EXISTS select_own_topic_progress ON user_topic_progress;
CREATE POLICY select_own_topic_progress ON user_topic_progress 
    FOR SELECT TO authenticated USING (user_id::text = (SELECT auth.uid())::text);

-- Admin Audit Log: Admin Own Logs Access
DROP POLICY IF EXISTS "Admin Own Logs Access" ON admin_audit_log;
CREATE POLICY "Admin Own Logs Access" ON admin_audit_log 
    FOR SELECT TO authenticated USING (admin_id::text = (SELECT auth.uid())::text);

-- Cohorts: Teacher Own Cohorts Access
DROP POLICY IF EXISTS "Teacher Own Cohorts Access" ON cohorts;
CREATE POLICY "Teacher Own Cohorts Access" ON cohorts 
    FOR SELECT TO authenticated USING (teacher_id::text = (SELECT auth.uid())::text);

-- Password Resets: Allow Public Insert (for forgot password flow)
DROP POLICY IF EXISTS "Allow Public Insert Password Resets" ON password_resets;
CREATE POLICY "Allow Public Insert Password Resets" ON password_resets 
    FOR INSERT TO public WITH CHECK (true);

-- Question Performance: Public Read Access
DROP POLICY IF EXISTS "Public Read Question Performance" ON question_performance;
CREATE POLICY "Public Read Question Performance" ON question_performance 
    FOR SELECT TO authenticated USING (true);

-- Refresh Tokens: User Own Refresh Tokens Access
DROP POLICY IF EXISTS "User Own Refresh Tokens Access" ON refresh_tokens;
CREATE POLICY "User Own Refresh Tokens Access" ON refresh_tokens 
    FOR SELECT TO authenticated USING (user_id::text = (SELECT auth.uid())::text);


-- 5. PERFORMANCE FIX: Indices for Foreign Keys (unindexed_foreign_keys)
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_admin_id ON admin_audit_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_cohort_members_student_id ON cohort_members(student_id);
CREATE INDEX IF NOT EXISTS idx_cohorts_teacher_id ON cohorts(teacher_id);
CREATE INDEX IF NOT EXISTS idx_consultation_notes_author_id ON consultation_notes(author_id);
CREATE INDEX IF NOT EXISTS idx_ecg_cases_diagnosis_id ON ecg_cases(diagnosis_id);
CREATE INDEX IF NOT EXISTS idx_notifications_sender_id ON notifications(sender_id);
CREATE INDEX IF NOT EXISTS idx_responses_question_id ON responses(question_id);
CREATE INDEX IF NOT EXISTS idx_user_items_item_id ON user_items(item_id);
CREATE INDEX IF NOT EXISTS idx_user_items_placed_at_room_id ON user_items(placed_at_room_id);
CREATE INDEX IF NOT EXISTS idx_user_question_progress_question_id ON user_question_progress(question_id);
