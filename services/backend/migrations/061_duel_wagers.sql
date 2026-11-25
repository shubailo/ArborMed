-- A reservation and its debit are committed together. Closing it records the
-- actual payout, so retries and recovery after a server restart cannot mint coins.
CREATE TABLE duel_wagers (
    id uuid PRIMARY KEY,
    user_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount integer NOT NULL CHECK (amount IN (5, 10, 25, 50, 100)),
    match_id uuid,
    expires_at timestamptz NOT NULL,
    payout integer CHECK (payout IN (0, amount, amount * 2)),
    closed_at timestamptz,
    CHECK ((payout IS NULL) = (closed_at IS NULL))
);
CREATE UNIQUE INDEX duel_wagers_one_open_per_user ON duel_wagers(user_id) WHERE closed_at IS NULL;
CREATE INDEX duel_wagers_open_expiry ON duel_wagers(expires_at) WHERE closed_at IS NULL;
CREATE INDEX duel_wagers_matches ON duel_wagers(match_id) WHERE match_id IS NOT NULL;
ALTER TABLE duel_wagers ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    -- Only the API may mutate balances or the records that prove a reward was earned.
    REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON users, user_claimed_quests, room_likes FROM PUBLIC;
    REVOKE ALL ON duel_wagers FROM PUBLIC;
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON users, user_claimed_quests, room_likes FROM anon;
        REVOKE ALL ON duel_wagers FROM anon;
    END IF;
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON users, user_claimed_quests, room_likes FROM authenticated;
        REVOKE ALL ON duel_wagers FROM authenticated;
    END IF;
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'med_buddy_app') THEN
        GRANT SELECT, INSERT, UPDATE ON duel_wagers TO med_buddy_app;
        CREATE POLICY backend_duel_wagers ON duel_wagers TO med_buddy_app USING (true) WITH CHECK (true);
    END IF;
END $$;

-- Enforce the invariant on new writes without rewriting historical balances.
ALTER TABLE users ADD CONSTRAINT users_coins_nonnegative CHECK (coins >= 0) NOT VALID;
