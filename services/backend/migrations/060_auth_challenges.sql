-- Invalidate pre-verification JWTs only for legacy accounts that finish email verification.
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_session_version uuid;

-- Existing one-time codes are superseded. A fresh request uses the purpose-bound challenge.
CREATE TABLE IF NOT EXISTS auth_challenges (
    email varchar(255) NOT NULL,
    purpose text NOT NULL CHECK (purpose IN ('registration', 'password-reset', 'email-verification')),
    registration_id uuid,
    user_id integer REFERENCES users(id) ON DELETE CASCADE,
    username varchar(255),
    display_name varchar(255),
    password_hash text,
    otp_digest bytea NOT NULL,
    attempts_left smallint NOT NULL DEFAULT 5 CHECK (attempts_left BETWEEN 0 AND 5),
    issued_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL DEFAULT (now() + interval '10 minutes'),
    PRIMARY KEY (email, purpose),
    CHECK (CASE WHEN purpose = 'registration'
                THEN registration_id IS NOT NULL AND user_id IS NULL AND password_hash IS NOT NULL AND username IS NOT NULL
                WHEN purpose = 'email-verification'
                THEN registration_id IS NOT NULL AND user_id IS NOT NULL AND password_hash IS NOT NULL
                ELSE registration_id IS NULL AND user_id IS NOT NULL AND password_hash IS NULL END)
);

ALTER TABLE auth_challenges ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON auth_challenges FROM PUBLIC;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON auth_challenges FROM anon;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE ALL ON auth_challenges FROM authenticated;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'med_buddy_app') THEN
        GRANT SELECT, INSERT, UPDATE, DELETE ON auth_challenges TO med_buddy_app;
        DROP POLICY IF EXISTS auth_challenges_backend ON auth_challenges;
        CREATE POLICY auth_challenges_backend ON auth_challenges TO med_buddy_app USING (true) WITH CHECK (true);
    END IF;
END $$;
