-- Add daily economy tracking columns to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS daily_coins_earned INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS daily_coins_softcap_progress INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_coin_reset_date DATE DEFAULT CURRENT_DATE;

-- Add a table for tracking claimed quests (to prevent double claiming)
CREATE TABLE IF NOT EXISTS user_claimed_quests (
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    quest_id VARCHAR(255) NOT NULL,
    claimed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, quest_id)
);
