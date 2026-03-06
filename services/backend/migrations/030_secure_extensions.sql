-- Migration 030: Secure Supabase Extensions
-- Fixes Supabase Security Lint: extension_in_public (Level: WARN)
-- Description: Move extensions away from the public schema to reduce attack surface and clutter.

-- 1. Create the dedicated schema for extensions (best practice)
CREATE SCHEMA IF NOT EXISTS extensions;

-- 2. Move pg_trgm to the new schema
ALTER EXTENSION "pg_trgm" SET SCHEMA extensions;

-- 3. Move other common extensions if they happen to be in public (failsafe)
DO $$ 
BEGIN 
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp') THEN
        ALTER EXTENSION "uuid-ossp" SET SCHEMA extensions;
    END IF;
END $$;

-- 4. Grant search path access
-- Supabase handles search_path for its default roles, but we ensure usage is granted.
GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;

-- Log completion
COMMENT ON SCHEMA extensions IS 'Secure schema for PostgreSQL extensions (Supabase best practice).';
