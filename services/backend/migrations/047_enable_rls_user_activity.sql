-- ------------------------------------------------------------------------------
-- 🛡️ Migration 047: Enable RLS and Security Policies for user_activity
-- Purpose: Resolves Supabase Database Linter error '0013_rls_disabled_in_public'.
--          Protects user activity logs with optimized, role-based RLS policies.
-- ------------------------------------------------------------------------------

-- 1. Enable Row Level Security (RLS) on public.user_activity
ALTER TABLE public.user_activity ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies if any (for idempotency)
DROP POLICY IF EXISTS "user_activity_select_policy" ON public.user_activity;
DROP POLICY IF EXISTS "user_activity_insert_policy" ON public.user_activity;
DROP POLICY IF EXISTS "user_activity_update_policy" ON public.user_activity;
DROP POLICY IF EXISTS "user_activity_delete_policy" ON public.user_activity;

-- 3. Consolidated SELECT policy (Students view own activity; Admins view all)
-- Uses (SELECT auth.uid()) to satisfy Supabase auth_rls_initplan performance lint.
-- Consolidates user and admin rules to satisfy multiple_permissive_policies lint.
CREATE POLICY "user_activity_select_policy" ON public.user_activity
    FOR SELECT TO authenticated
    USING (
        (user_id::text = (SELECT auth.uid())::text)
        OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id::text = (SELECT auth.uid())::text AND role IN ('admin', 'superuser')
        )
    );

-- 4. INSERT policy (Users can only record activity for themselves, or Admins for anyone)
CREATE POLICY "user_activity_insert_policy" ON public.user_activity
    FOR INSERT TO authenticated
    WITH CHECK (
        (user_id::text = (SELECT auth.uid())::text)
        OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id::text = (SELECT auth.uid())::text AND role IN ('admin', 'superuser')
        )
    );

-- 5. UPDATE policy (Audit log immutability: only Admins can update activity records)
CREATE POLICY "user_activity_update_policy" ON public.user_activity
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id::text = (SELECT auth.uid())::text AND role IN ('admin', 'superuser')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id::text = (SELECT auth.uid())::text AND role IN ('admin', 'superuser')
        )
    );

-- 6. DELETE policy (Only Admins can delete activity records)
CREATE POLICY "user_activity_delete_policy" ON public.user_activity
    FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id::text = (SELECT auth.uid())::text AND role IN ('admin', 'superuser')
        )
    );

-- 7. Permissions and Role Grants
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'med_buddy_app') THEN
        GRANT ALL ON public.user_activity TO med_buddy_app;
        IF EXISTS (SELECT 1 FROM pg_class WHERE relkind = 'S' AND relname = 'user_activity_id_seq') THEN
            GRANT USAGE, SELECT ON SEQUENCE user_activity_id_seq TO med_buddy_app;
        END IF;
    END IF;
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'service_role') THEN
        GRANT ALL ON public.user_activity TO service_role;
        IF EXISTS (SELECT 1 FROM pg_class WHERE relkind = 'S' AND relname = 'user_activity_id_seq') THEN
            GRANT USAGE, SELECT ON SEQUENCE user_activity_id_seq TO service_role;
        END IF;
    END IF;
END $$;

GRANT SELECT, INSERT ON public.user_activity TO authenticated;

COMMENT ON TABLE public.user_activity IS 'Stores user actions and event tracking with Row Level Security enabled.';
