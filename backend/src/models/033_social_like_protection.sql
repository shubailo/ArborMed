-- Migration 033: Social Like Protection
-- Prevents users from liking the same room multiple times to farm coins.

CREATE TABLE IF NOT EXISTS room_likes (
    id SERIAL PRIMARY KEY,
    liker_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    receiver_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(liker_id, receiver_id)
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_room_likes_receiver ON room_likes(receiver_id);

-- Enable RLS (Supabase Security Requirement)
ALTER TABLE room_likes ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to view likes
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'room_likes' AND policyname = 'Allow authenticated view'
    ) THEN
        CREATE POLICY "Allow authenticated view" ON room_likes FOR SELECT TO authenticated USING (true);
    END IF;
END $$;
