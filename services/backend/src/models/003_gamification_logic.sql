-- Add Streak tracking to Users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS streak_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_active_date TIMESTAMP WITH TIME ZONE;

-- Create User Mastery Table
CREATE TABLE IF NOT EXISTS user_mastery (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    subject VARCHAR(100) NOT NULL, -- Corresponds to topic slug or name
    proficiency INTEGER DEFAULT 0, -- 0 to 100 progress to next level
    level INTEGER DEFAULT 1, -- Current Mastery Level
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, subject)
);

-- Note: 'items' table 'type' column is VARCHAR, so 'skin' type is supported without schema change.
