-- Insert System Bot: Dr. Grastyán Endre
INSERT INTO users (id, email, password_hash, username, display_name, role, coins, xp, level)
VALUES (999, 'endre@medbuddy.ai', '$2b$10$SYSTEM_BOT_HASH_PLACEHOLDER', 'grastyan', 'Dr. Grastyán Endre', 'student', 9999, 5000, 50)
ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name, username = EXCLUDED.username;

-- Optionally give Hemmy a room if we want it to be visitable
-- For now, Hemmy is just a social presence. 
-- In the future we can equip his room with best-practice medical layouts.
