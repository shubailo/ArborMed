-- Migration 041: Fix RLS Performance Lints
-- 1. Optimize user_claimed_quests policies (Prevent re-evaluation of auth.uid)
DROP POLICY IF EXISTS "Users can view their own claimed quests" ON user_claimed_quests;
CREATE POLICY "Users can view their own claimed quests" ON user_claimed_quests
    FOR SELECT
    TO authenticated
    USING ((SELECT auth.uid())::text = user_id::text);

DROP POLICY IF EXISTS "Users can insert their own claimed quests" ON user_claimed_quests;
CREATE POLICY "Users can insert their own claimed quests" ON user_claimed_quests
    FOR INSERT
    TO authenticated
    WITH CHECK ((SELECT auth.uid())::text = user_id::text);

-- 2. Consolidate room_likes policies (Resolve multiple permissive policies warning)
-- Drop the redundant "Allow authenticated view" policy if it exists
DROP POLICY IF EXISTS "Allow authenticated view" ON room_likes;

-- Ensure "Users can see all likes" remains optimized
DROP POLICY IF EXISTS "Users can see all likes" ON room_likes;
CREATE POLICY "Users can see all likes" ON room_likes
    FOR SELECT
    TO authenticated
    USING (true);
