-- Consolidation of permissive RLS policies for question_reports
-- Fixes Supabase Lint: auth_rls_initplan (Performance), multiple_permissive_policies (Performance)

-- 1. Drop existing policies (legacy and new ones for idempotency)
DROP POLICY IF EXISTS "Students create reports" ON question_reports;
DROP POLICY IF EXISTS "Students view own reports" ON question_reports;
DROP POLICY IF EXISTS "Admins full access reports" ON question_reports;
DROP POLICY IF EXISTS "Allow authenticated read reports" ON question_reports;
DROP POLICY IF EXISTS "question_reports_insert_policy" ON question_reports;
DROP POLICY IF EXISTS "question_reports_select_policy" ON question_reports;
DROP POLICY IF EXISTS "question_reports_update_policy" ON question_reports;
DROP POLICY IF EXISTS "question_reports_delete_policy" ON question_reports;

-- 2. Create consolidated INSERT policy
-- Allows students to create reports for themselves, or admins for any user.
-- Uses (SELECT auth.uid()) to avoid row-by-row re-evaluation.
CREATE POLICY "question_reports_insert_policy" ON question_reports
    FOR INSERT TO authenticated
    WITH CHECK (
        (user_id::text = (SELECT auth.uid())::text)
        OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE id::text = (SELECT auth.uid())::text AND role = 'admin'
        )
    );

-- 3. Create consolidated SELECT policy
-- Allows students to view their own reports, or admins to view all.
CREATE POLICY "question_reports_select_policy" ON question_reports
    FOR SELECT TO authenticated
    USING (
        (user_id::text = (SELECT auth.uid())::text)
        OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE id::text = (SELECT auth.uid())::text AND role = 'admin'
        )
    );

-- 4. Create consolidated UPDATE policy
-- Only admins can update reports (e.g., changing status or adding notes).
CREATE POLICY "question_reports_update_policy" ON question_reports
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id::text = (SELECT auth.uid())::text AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id::text = (SELECT auth.uid())::text AND role = 'admin'
        )
    );

-- 5. Create consolidated DELETE policy
-- Only admins can delete reports.
CREATE POLICY "question_reports_delete_policy" ON question_reports
    FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id::text = (SELECT auth.uid())::text AND role = 'admin'
        )
    );

-- Log completion
COMMENT ON TABLE question_reports IS 'Table for student reports on questions with optimized RLS policies.';
