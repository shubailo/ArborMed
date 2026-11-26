-- The readiness endpoint compares only the migration name and digest.
DO $$
DECLARE
    backend_role text;
BEGIN
    FOREACH backend_role IN ARRAY ARRAY['med_buddy_app', 'service_role'] LOOP
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = backend_role) THEN
            EXECUTE format('GRANT SELECT (checksum) ON arbormed_schema_migrations TO %I', backend_role);
        END IF;
    END LOOP;
END $$;
