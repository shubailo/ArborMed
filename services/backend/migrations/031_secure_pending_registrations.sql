-- Migration 031: Hardening Pending Registrations
-- Fixes Supabase Security Lints: rls_disabled_in_public & sensitive_columns_exposed
-- Description: Enable RLS and ensure no public/authenticated access to sensitive OTP data.

-- 1. Enable RLS on the table
-- By enabling RLS without adding any "FOR ALL" or "FOR SELECT" policies, 
-- the table becomes completely private to everyone except the service_role key.
ALTER TABLE pending_registrations ENABLE ROW LEVEL SECURITY;

-- 2. Explicitly Deny all access to 'anon' and 'authenticated' roles
-- (Added for clarity and defense-in-depth, though default-deny is now active)
DROP POLICY IF EXISTS "Deny all public access to pending registrations" ON pending_registrations;
CREATE POLICY "Deny all public access to pending registrations" ON pending_registrations
    FOR ALL
    TO anon, authenticated
    USING (false);

-- Note: Our Backend uses the 'service_role' (or has BypassRLS), so it can 
-- still manage this table without being affected by these restrictions.

-- Log completion
COMMENT ON TABLE pending_registrations IS 'Table for temporary registration data. Hardened with RLS to prevent OTP exposure.';
