-- Add Profile-related fields to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS username VARCHAR(255) UNIQUE,
ADD COLUMN IF NOT EXISTS display_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS avatar_id INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0;

-- Migration for legacy users: auto-generate username from email
-- If a username collision occurs, PostgreSQL will error, which is fine for this manual migration step
-- In a real scenario, we might append random digits, but this is simple for MVP.
UPDATE users 
SET username = LOWER(split_part(email, '@', 1)),
    display_name = split_part(email, '@', 1)
WHERE username IS NULL;
