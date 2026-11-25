-- 016 initialized pre-existing users' last_activity_at from their registration
-- date. Reconcile that placeholder with observed actions; an unexplained NULL
-- is more accurate than a login time inferred from account creation.
DO $column$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_attribute WHERE attrelid = 'users'::regclass
        AND attname = 'last_activity_at' AND NOT attisdropped
    ) THEN
        ALTER TABLE users ADD COLUMN last_activity_at timestamptz;
    END IF;
END $column$;

CREATE TEMP TABLE arbormed_activity_evidence (
    user_id integer, seen_at timestamptz
) ON COMMIT DROP;

-- Some legacy installations lack optional modules. In particular, the two
-- historical quest schemas use different timestamp types. A timestamp without
-- a zone cannot establish an instant if the writer's time zone is unknown.
DO $collect$
DECLARE
    src record;
    relation regclass;
BEGIN
    IF EXISTS (SELECT FROM pg_attribute WHERE attrelid = 'responses'::regclass AND NOT attisdropped
               AND attname = 'created_at' AND atttypid = 'timestamptz'::regtype) THEN
        INSERT INTO pg_temp.arbormed_activity_evidence
        SELECT COALESCE(r.user_id, s.user_id), MAX(r.created_at)
        FROM responses r LEFT JOIN quiz_sessions s ON s.id = r.session_id
        GROUP BY COALESCE(r.user_id, s.user_id);
    END IF;

    FOR src IN SELECT * FROM (VALUES
        ('users',               'id',           'last_active_date', NULL,             'true'),
        ('refresh_tokens',      'user_id',      'created_at',       NULL,             'true'),
        ('security_audits',     'user_id',      'created_at',       'action_type',    'action_type IN (''LOGIN_SUCCESS'', ''PASSWORD_CHANGE'')'),
        ('quiz_sessions',       'user_id',      'started_at',       NULL,             'true'),
        ('quiz_sessions',       'user_id',      'completed_at',     NULL,             'true'),
        ('user_activity',       'user_id',      'created_at',       'action',         'action = ''quiz_answer'''),
        ('user_topic_progress', 'user_id',      'last_studied_at',  'total_answered', 'total_answered > 0'),
        ('user_claimed_quests', 'user_id',      'claimed_at',       NULL,             'true'),
        ('question_reports',    'user_id',      'created_at',       NULL,             'true'),
        ('consultation_notes',  'author_id',    'created_at',       NULL,             'true'),
        ('room_likes',          'liker_id',     'created_at',       NULL,             'true'),
        ('friendships',         'requester_id', 'created_at',       NULL,             'true'),
        ('friendships',         'receiver_id',  'updated_at',       'status',         'status = ''accepted''')
    ) AS sources(relation_name, actor, event_time, filter_column, condition)
    LOOP
        relation := to_regclass(src.relation_name);
        IF EXISTS (SELECT FROM pg_attribute WHERE attrelid = relation AND NOT attisdropped
                   AND attname = src.event_time AND atttypid = 'timestamptz'::regtype)
        AND EXISTS (SELECT FROM pg_attribute WHERE attrelid = relation AND NOT attisdropped AND attname = src.actor)
        AND (src.filter_column IS NULL OR EXISTS (
            SELECT FROM pg_attribute WHERE attrelid = relation AND NOT attisdropped AND attname = src.filter_column
        )) THEN
            EXECUTE format('INSERT INTO pg_temp.arbormed_activity_evidence
                SELECT %1$I, MAX(%2$I) FROM %3$s WHERE %4$s GROUP BY %1$I',
                src.actor, src.event_time, relation, src.condition);
        END IF;
    END LOOP;
END $collect$;

-- Read the current target row in SET and WHERE. If a live request updated it
-- while this statement waited on its lock, PostgreSQL retains the newer instant.
WITH history AS (
    SELECT u.id, MAX(e.seen_at) AS seen_at
    FROM users u LEFT JOIN pg_temp.arbormed_activity_evidence e
        ON e.user_id = u.id AND (u.created_at IS NULL OR e.seen_at >= u.created_at)
    GROUP BY u.id
)
UPDATE users u
SET last_activity_at = GREATEST(NULLIF(u.last_activity_at, u.created_at), h.seen_at)
FROM history h
WHERE u.id = h.id
  AND u.last_activity_at IS DISTINCT FROM GREATEST(NULLIF(u.last_activity_at, u.created_at), h.seen_at);

DROP TABLE pg_temp.arbormed_activity_evidence;
