-- Existing responses keep their historical grades and have no retry receipt.
ALTER TABLE responses ADD COLUMN IF NOT EXISTS submission_id UUID;
ALTER TABLE responses ADD COLUMN IF NOT EXISTS submission_input JSONB;
ALTER TABLE responses ADD COLUMN IF NOT EXISTS submission_result JSONB;
CREATE UNIQUE INDEX IF NOT EXISTS responses_user_submission_id
    ON responses (user_id, submission_id) WHERE submission_id IS NOT NULL;

ALTER TABLE responses ADD COLUMN IF NOT EXISTS reward_day DATE;
CREATE UNIQUE INDEX IF NOT EXISTS responses_daily_question_reward
    ON responses (user_id, question_id, reward_day) WHERE reward_day IS NOT NULL;

-- The Express backend records answers and serves history; clients must not be
-- able to forge or truncate receipts through PostgREST, even with default grants.
ALTER TABLE public.responses ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.responses FROM PUBLIC;
DO $$
DECLARE
    target_role TEXT;
    response_sequence REGCLASS := pg_get_serial_sequence('public.responses', 'id');
BEGIN
    FOREACH target_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = target_role) THEN
            EXECUTE format('REVOKE ALL ON public.responses FROM %I', target_role);
        END IF;
    END LOOP;
    FOREACH target_role IN ARRAY ARRAY['med_buddy_app', 'service_role'] LOOP
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = target_role) THEN
            EXECUTE format('GRANT SELECT, INSERT, UPDATE ON public.responses TO %I', target_role);
            EXECUTE format('DROP POLICY IF EXISTS %I ON public.responses', 'record_answers_' || target_role);
            EXECUTE format('CREATE POLICY %I ON public.responses TO %I USING (true) WITH CHECK (true)',
                'record_answers_' || target_role, target_role);
            IF response_sequence IS NOT NULL THEN
                EXECUTE format('GRANT USAGE ON SEQUENCE %s TO %I', response_sequence, target_role);
            END IF;
        END IF;
    END LOOP;
END $$;
