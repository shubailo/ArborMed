-- Add last_activity_at to users table for tracking admin performance metrics
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMP WITH TIME ZONE;

-- Initialize with created_at for existing users
UPDATE users SET last_activity_at = created_at WHERE last_activity_at IS NULL;
