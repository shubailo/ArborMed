-- Add Avatar Creator columns to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_config JSONB DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS has_received_founders_pack BOOLEAN DEFAULT FALSE;

-- Add is_free column to items
ALTER TABLE items ADD COLUMN IF NOT EXISTS is_free BOOLEAN DEFAULT FALSE;

-- Create monitoring log table for missing assets (as discussed in plan)
CREATE TABLE IF NOT EXISTS avatar_err_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    missing_id VARCHAR(255),
    logged_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Initial migration for Founder Pack (500 coins)
-- Logic: Grant to users who already own legacy items (skin/bean_body slots)
-- and haven't received it yet.
UPDATE users 
SET coins = coins + 500, 
    has_received_founders_pack = TRUE
WHERE id IN (
    SELECT DISTINCT user_id 
    FROM user_items 
    INNER JOIN items ON user_items.item_id = items.id
    WHERE items.slot_type IN ('skin', 'bean_body')
)
AND has_received_founders_pack = FALSE;
