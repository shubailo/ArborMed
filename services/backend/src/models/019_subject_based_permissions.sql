-- Migration 019: Subject-Based Admin Permissions
-- Description: Adds subject assignment for admins and tracks question authorship

-- 1. Add assigned_subject_id to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS assigned_subject_id INTEGER REFERENCES topics(id);

-- 2. Add created_by to questions table
ALTER TABLE questions ADD COLUMN IF NOT EXISTS created_by INTEGER REFERENCES users(id);

-- 3. Add index for performance
CREATE INDEX IF NOT EXISTS idx_users_assigned_subject ON users(assigned_subject_id);
CREATE INDEX IF NOT EXISTS idx_questions_created_by ON questions(created_by);

-- 4. Add a view for admin question counts
CREATE OR REPLACE VIEW admin_question_stats AS
SELECT 
    u.id as admin_id,
    u.email,
    u.assigned_subject_id,
    t.name_en as assigned_subject_name,
    COUNT(q.id) as total_questions_created,
    COUNT(CASE WHEN q.active = TRUE THEN 1 END) as active_questions
FROM users u
LEFT JOIN questions q ON q.created_by = u.id
LEFT JOIN topics t ON t.id = u.assigned_subject_id
WHERE u.role = 'admin'
GROUP BY u.id, u.email, u.assigned_subject_id, t.name_en;

-- 5. Grant permissions
GRANT SELECT ON admin_question_stats TO med_buddy_app;
