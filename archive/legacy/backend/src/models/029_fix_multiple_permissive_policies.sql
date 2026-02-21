-- Consolidation of permissive RLS policies for analytics_snapshots
-- Fixes Supabase Lint: multiple_permissive_policies (Level: WARN)

-- 1. Drop the legacy separate policies
DROP POLICY IF EXISTS "Users Own Snapshots Access" ON analytics_snapshots;
DROP POLICY IF EXISTS "Admins View All Snapshots" ON analytics_snapshots;

-- 2. Create a single consolidated policy
-- This is more efficient as Postgres only has to evaluate one rule.
CREATE POLICY "analytics_snapshots_select_policy" ON analytics_snapshots
    FOR SELECT TO authenticated
    USING (
        -- User owns the record
        (user_id::text = (SELECT auth.uid())::text)
        OR 
        -- User is an admin
        EXISTS (
            SELECT 1 FROM users 
            WHERE id::text = (SELECT auth.uid())::text AND role = 'admin'
        )
    );

-- Log completion for tracking
COMMENT ON POLICY "analytics_snapshots_select_policy" ON analytics_snapshots IS 'Consolidated access for users and admins to resolve multiple_permissive_policies lint.';
