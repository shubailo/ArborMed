-- Migration 049: Grant Quest and Room Table Permissions & Default Privileges
-- Ensures backend role (med_buddy_app / service_role) has full CRUD access to gamification, room, and quest tables

-- 1. Ensure user_claimed_quests table exists and has RLS enabled
CREATE TABLE IF NOT EXISTS public.user_claimed_quests (
    user_id INTEGER REFERENCES public.users(id) ON DELETE CASCADE,
    quest_id VARCHAR(255) NOT NULL,
    claimed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, quest_id)
);

ALTER TABLE public.user_claimed_quests ENABLE ROW LEVEL SECURITY;

-- 2. Performance-optimized RLS policies on user_claimed_quests
DROP POLICY IF EXISTS "Users can view their own claimed quests" ON public.user_claimed_quests;
CREATE POLICY "Users can view their own claimed quests" ON public.user_claimed_quests
    FOR SELECT
    TO authenticated
    USING ((user_id)::text = ((SELECT auth.uid()))::text);

DROP POLICY IF EXISTS "Users can insert their own claimed quests" ON public.user_claimed_quests;
CREATE POLICY "Users can insert their own claimed quests" ON public.user_claimed_quests
    FOR INSERT
    TO authenticated
    WITH CHECK ((user_id)::text = ((SELECT auth.uid()))::text);

-- 3. Explicit Grants for backend application role and service role
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'med_buddy_app') THEN
        GRANT ALL ON public.user_claimed_quests TO med_buddy_app;
        GRANT ALL ON public.user_rooms TO med_buddy_app;
        GRANT ALL ON public.room_likes TO med_buddy_app;
        GRANT ALL ON public.user_items TO med_buddy_app;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        GRANT ALL ON public.user_claimed_quests TO service_role;
        GRANT ALL ON public.user_rooms TO service_role;
        GRANT ALL ON public.room_likes TO service_role;
        GRANT ALL ON public.user_items TO service_role;
    END IF;
END $$;

-- 4. Set Default Privileges so future tables automatically grant to med_buddy_app
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'med_buddy_app') THEN
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO med_buddy_app;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO med_buddy_app;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;
    END IF;
END $$;
