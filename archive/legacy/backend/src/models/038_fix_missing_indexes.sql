-- 038_fix_missing_indexes.sql
-- Fixes Supabase Lint: unindexed_foreign_keys (Performance)

-- Identify foreign keys without covering indexes and add them for performance.

-- admin_audit_log(admin_id) - Used for auditing admin actions.
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_admin_id ON admin_audit_log(admin_id);

-- security_audits(admin_id) - Used for tracking security-related changes.
CREATE INDEX IF NOT EXISTS idx_security_audits_admin_id ON security_audits(admin_id);

-- Log completion
COMMENT ON INDEX idx_admin_audit_log_admin_id IS 'Index for foreign key coverage to resolve Supabase lint unindexed_foreign_keys.';
COMMENT ON INDEX idx_security_audits_admin_id IS 'Index for foreign key coverage to resolve Supabase lint unindexed_foreign_keys.';
