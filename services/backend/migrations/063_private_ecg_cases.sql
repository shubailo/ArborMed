-- Case presentation and post-submission feedback are served by the backend.
ALTER TABLE ecg_cases ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Access" ON ecg_cases;
REVOKE ALL ON ecg_cases FROM PUBLIC;
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON ecg_cases FROM anon;
  END IF;
  IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON ecg_cases FROM authenticated;
  END IF;
  IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'med_buddy_app') THEN
    GRANT SELECT, INSERT, UPDATE, DELETE ON ecg_cases TO med_buddy_app;
    CREATE POLICY backend_ecg_cases ON ecg_cases TO med_buddy_app USING (true) WITH CHECK (true);
  END IF;
END $$;
