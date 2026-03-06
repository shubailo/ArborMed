-- Migration 025: Increase Slug Length Limits
-- Description: One of our topics has a 63-character slug, but user_topic_progress only allows 50.
-- This migration increases the limit to 100 to match the topics table.

ALTER TABLE public.user_topic_progress ALTER COLUMN topic_slug TYPE VARCHAR(100);

-- Also checking and updating any other potential limited slug columns
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'user_question_progress' AND column_name = 'topic_slug'
    ) THEN
        ALTER TABLE public.user_question_progress ALTER COLUMN topic_slug TYPE VARCHAR(100);
    END IF;
END $$;
