-- 🛡️ Phase 7: Security Audit Logs
-- Tracks sensitive administrative and auth actions

CREATE TABLE IF NOT EXISTS security_audits (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    admin_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- If an admin did something to a user
    action_type TEXT NOT NULL, -- e.g., 'LOGIN_SUCCESS', 'PASSWORD_CHANGE', 'ROLE_UPDATE', 'DATA_EXPORT'
    severity TEXT CHECK (severity IN ('INFO', 'WARNING', 'CRITICAL')) DEFAULT 'INFO',
    metadata JSONB, -- IPs, device info, or specific change details
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster audit reviews
CREATE INDEX idx_security_audits_user ON security_audits(user_id);
CREATE INDEX idx_security_audits_action ON security_audits(action_type);
CREATE INDEX idx_security_audits_time ON security_audits(created_at);

-- Enable RLS (Only admins should ever see these logs)
ALTER TABLE security_audits ENABLE ROW LEVEL SECURITY;

CREATE POLICY admin_audit_access ON security_audits
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role IN ('admin', 'superuser')
        )
    );
