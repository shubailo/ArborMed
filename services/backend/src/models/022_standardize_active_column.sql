-- Migration: 022_standardize_active_column.sql
-- Purpose: Rename 'active' to 'is_active' for consistency across all tables.

DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'questions' AND column_name = 'active'
  ) THEN
    ALTER TABLE questions RENAME COLUMN active TO is_active;
  END IF;
END $$;

-- Ensure all existing questions are set to active if they were NULL (safety)
UPDATE questions SET is_active = true WHERE is_active IS NULL;

-- Re-grant permissions for the app role (idempotent)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.questions TO med_buddy_app;
