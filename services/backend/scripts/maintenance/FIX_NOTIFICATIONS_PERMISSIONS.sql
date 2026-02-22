-- FIX: Grant permissions to med_buddy_app for notifications table
-- Run this in your Supabase SQL Editor

-- Grant all privileges on notifications table
GRANT ALL PRIVILEGES ON TABLE notifications TO med_buddy_app;

-- Grant all privileges on admin_audit_log table (if it exists)
GRANT ALL PRIVILEGES ON TABLE admin_audit_log TO med_buddy_app;

-- Grant usage on the sequences
GRANT USAGE, SELECT ON SEQUENCE notifications_id_seq TO med_buddy_app;
GRANT USAGE, SELECT ON SEQUENCE admin_audit_log_id_seq TO med_buddy_app;

-- Verify permissions
SELECT 
    tablename,
    tableowner,
    has_table_privilege('med_buddy_app', 'notifications', 'SELECT') as can_select,
    has_table_privilege('med_buddy_app', 'notifications', 'INSERT') as can_insert,
    has_table_privilege('med_buddy_app', 'notifications', 'UPDATE') as can_update
FROM pg_tables 
WHERE tablename = 'notifications';
