-- Migration 024: Fix Function Search Path Mutable warnings
-- Description: Sets search_path = public for sensitive functions to prevent search path hijacking and silence Supabase lints.
-- Note: Code inside these functions is already schema-qualified (e.g., public.users).

ALTER FUNCTION public.validate_and_reset_password(TEXT, TEXT, TEXT) SET search_path = public;
ALTER FUNCTION public.check_password_reset_rate_limit(TEXT) SET search_path = public;
