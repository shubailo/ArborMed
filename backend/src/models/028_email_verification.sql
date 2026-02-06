-- Add is_email_verified to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_email_verified BOOLEAN DEFAULT FALSE;

-- Force existing users to verify (as requested)
-- Note: You might want to exclude 'admin' users from this if you're testing, 
-- but following the "force them" instruction strictly:
UPDATE users SET is_email_verified = FALSE;

-- Explicitly allow admins to skip manual verification if needed for convenience during dev,
-- but the instruction was "force THEM". Let's stick to the instruction.
-- UPDATE users SET is_email_verified = TRUE WHERE role = 'admin';
