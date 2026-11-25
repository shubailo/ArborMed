-- Runtime readiness needs the names of applied migrations; only the migrator writes the ledger.
DO $$
DECLARE
    backend_role text;
BEGIN
    FOREACH backend_role IN ARRAY ARRAY['med_buddy_app', 'service_role'] LOOP
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = backend_role) THEN
            EXECUTE format('GRANT SELECT (filename) ON arbormed_schema_migrations TO %I', backend_role);
            EXECUTE format('CREATE POLICY %I ON arbormed_schema_migrations FOR SELECT TO %I USING (true)',
                'read_applied_migrations_' || backend_role, backend_role);
        END IF;
    END LOOP;
END $$;
