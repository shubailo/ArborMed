-- Migration 033: Social Like Protection
-- Prevents users from liking the same room multiple times to farm coins.

CREATE TABLE IF NOT EXISTS room_likes (
    id SERIAL PRIMARY KEY,
    liker_id INTEGER,
    receiver_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(liker_id, receiver_id)
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_room_likes_receiver ON room_likes(receiver_id);

-- Enable RLS
ALTER TABLE room_likes ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'room_likes' AND policyname = 'Users can see all likes') THEN
        CREATE POLICY "Users can see all likes" ON room_likes FOR SELECT TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'room_likes' AND policyname = 'Users can like rooms') THEN
        CREATE POLICY "Users can like rooms" ON room_likes FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid())::text = liker_id::text);
    END IF;
END $$;
