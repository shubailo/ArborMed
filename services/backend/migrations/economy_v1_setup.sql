-- Migration: Add Economy Columns & Claimed Quests Table
-- Purpose: Support soft caps, daily resets, and quest reward tracking.

-- 1. Add columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS daily_coins_earned INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS daily_coins_softcap_progress INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_coin_reset_date DATE DEFAULT CURRENT_DATE;

-- 2. Create user_claimed_quests table
CREATE TABLE IF NOT EXISTS user_claimed_quests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    quest_id VARCHAR(255) NOT NULL,
    claimed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, quest_id)
);

-- Index for performance on lookups
CREATE INDEX IF NOT EXISTS idx_user_claimed_quests_user_quest ON user_claimed_quests(user_id, quest_id);

-- 3. Security: Enable RLS and add policies
ALTER TABLE user_claimed_quests ENABLE ROW LEVEL SECURITY;

-- Users can view their own claimed quests
CREATE POLICY "Users can view their own claimed quests" ON user_claimed_quests
    FOR SELECT
    TO authenticated
    USING ((SELECT auth.uid())::text = user_id::text);

-- Backend / Service role typically has full access, 
-- but we define a policy for the authenticated user to insert via service logic if needed.
CREATE POLICY "Users can insert their own claimed quests" ON user_claimed_quests
    FOR INSERT
    TO authenticated
    WITH CHECK ((SELECT auth.uid())::text = user_id::text);
