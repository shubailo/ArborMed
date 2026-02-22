-- Supabase Performance Optimizations
-- Description: Add missing foreign key indexes and remove unused indexes.
-- Note: CREATE INDEX CONCURRENTLY cannot be run within a transaction block.

-- 1. Remove Unused Index
DROP INDEX IF EXISTS idx_admin_audit_log_admin_id;

-- 2. Add Missing Foreign Key Indexes
-- Use CONCURRENTLY to avoid locking tables for writes during index creation

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cohort_members_student_id ON public.cohort_members(student_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cohorts_teacher_id ON public.cohorts(teacher_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_consultation_notes_author_id ON public.consultation_notes(author_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ecg_cases_diagnosis_id ON public.ecg_cases(diagnosis_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_sender_id ON public.notifications(sender_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_password_resets_user_id ON public.password_resets(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_quiz_sessions_user_id ON public.quiz_sessions(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_topics_parent_id ON public.topics(parent_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_items_item_id ON public.user_items(item_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_items_placed_at_room_id ON public.user_items(placed_at_room_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_items_user_id ON public.user_items(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_assigned_subject_id ON public.users(assigned_subject_id);
