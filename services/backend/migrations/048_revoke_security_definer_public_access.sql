-- ------------------------------------------------------------------------------
-- 🛡️ Migration 048: Secure SECURITY DEFINER Functions
-- Purpose: Resolves Supabase Database Linter warnings:
--          - 0028_anon_security_definer_function_executable
--          - 0029_authenticated_security_definer_function_executable
--
-- Details:
-- By default, PostgreSQL grants EXECUTE to PUBLIC on newly created functions.
-- This exposed SECURITY DEFINER functions via PostgREST RPC (/rest/v1/rpc/...)
-- to anonymous ('anon') and authenticated ('authenticated') roles.
--
-- This migration revokes public execution permissions and drops obsolete overloads.
-- ------------------------------------------------------------------------------

-- 1. Drop obsolete 4-parameter overload if present
DROP FUNCTION IF EXISTS public.validate_and_reset_password(character varying, character varying, character varying, inet);
DROP FUNCTION IF EXISTS public.validate_and_reset_password(varchar, varchar, varchar, inet);

-- 2. Dynamically revoke EXECUTE from PUBLIC, anon, and authenticated on all overloads
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT p.oid, n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) as args
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname IN ('check_password_reset_rate_limit', 'validate_and_reset_password')
    LOOP
        -- Revoke execute from untrusted client roles
        EXECUTE format('REVOKE EXECUTE ON FUNCTION %I.%I(%s) FROM PUBLIC, anon, authenticated;', r.nspname, r.proname, r.args);
        
        -- Grant execute only to backend service roles
        IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'service_role') THEN
            EXECUTE format('GRANT EXECUTE ON FUNCTION %I.%I(%s) TO service_role;', r.nspname, r.proname, r.args);
        END IF;
        IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'med_buddy_app') THEN
            EXECUTE format('GRANT EXECUTE ON FUNCTION %I.%I(%s) TO med_buddy_app;', r.nspname, r.proname, r.args);
        END IF;
    END LOOP;
END $$;
