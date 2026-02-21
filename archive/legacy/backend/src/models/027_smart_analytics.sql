-- Add retention and stability columns to user_topic_progress
ALTER TABLE user_topic_progress ADD COLUMN IF NOT EXISTS retention_score FLOAT DEFAULT 0;
ALTER TABLE user_topic_progress ADD COLUMN IF NOT EXISTS stability FLOAT DEFAULT 0;
ALTER TABLE user_topic_progress ADD COLUMN IF NOT EXISTS last_reviewed_at TIMESTAMP WITH TIME ZONE;

-- Create analytics_snapshots table for historical tracking
CREATE TABLE IF NOT EXISTS analytics_snapshots (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    snapshot_date DATE NOT NULL,
    readiness_score FLOAT DEFAULT 0,
    retention_avg FLOAT DEFAULT 0,
    weakest_topic_slug VARCHAR(255),
    strongest_topic_slug VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, snapshot_date)
);

-- Index for fast retrieval of history
CREATE INDEX IF NOT EXISTS idx_analytics_snapshots_user_date ON analytics_snapshots(user_id, snapshot_date);

-- Security: Enable RLS for analytics_snapshots
ALTER TABLE analytics_snapshots ENABLE ROW LEVEL SECURITY;

-- 1. Users can view their own snapshots
CREATE POLICY "Users Own Snapshots Access" ON analytics_snapshots 
    FOR SELECT TO authenticated USING (user_id::text = (SELECT auth.uid())::text);

-- 2. Admins can view all snapshots (Using standard admin check from 020)
CREATE POLICY "Admins View All Snapshots" ON analytics_snapshots 
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id::text = (SELECT auth.uid())::text AND role = 'admin'
        )
    );

-- 3. System (med_buddy_app) Bypass is handled via role grant in 020, but just in case for new tables:
-- Note: 'med_buddy_app' usually has BYPASSRLS, so no specific policy needed for service role if configured correctly.
