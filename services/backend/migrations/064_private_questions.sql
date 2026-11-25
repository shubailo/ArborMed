-- Express exposes a student-safe question projection. Direct client reads include grading keys.
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Access" ON questions;
REVOKE ALL ON questions FROM PUBLIC;
DO $$
DECLARE
    target_role text;
BEGIN
    FOREACH target_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = target_role) THEN
            EXECUTE format('REVOKE ALL ON questions FROM %I', target_role);
        END IF;
    END LOOP;
    FOREACH target_role IN ARRAY ARRAY['med_buddy_app', 'service_role'] LOOP
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = target_role) THEN
            EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON questions TO %I', target_role);
            EXECUTE format('CREATE POLICY %I ON questions TO %I USING (true) WITH CHECK (true)',
                'backend_questions_' || target_role, target_role);
        END IF;
    END LOOP;
END $$;
