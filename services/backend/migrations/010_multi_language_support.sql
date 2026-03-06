-- Migration: 010_multi_language_support.sql
-- Purpose: Add multi-language support for questions (English and Hungarian)

-- 1. Add Hungarian language columns for question content
ALTER TABLE questions 
ADD COLUMN IF NOT EXISTS question_text_hu TEXT,
ADD COLUMN IF NOT EXISTS explanation_hu TEXT;

-- 2. Rename existing text column to question_text_en for clarity
-- First, check if the column exists and rename it
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'questions' AND column_name = 'text'
  ) THEN
    ALTER TABLE questions RENAME COLUMN text TO question_text_en;
  END IF;
END $$;

-- 3. Rename existing explanation column to explanation_en for clarity
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'questions' AND column_name = 'explanation'
  ) THEN
    ALTER TABLE questions RENAME COLUMN explanation TO explanation_en;
  END IF;
END $$;

-- 4. Add language columns for options (stored in JSONB)
-- We'll store options as: { "en": ["Option A", "Option B", ...], "hu": ["Opció A", "Opció B", ...] }
-- Update existing options to new format
UPDATE questions 
SET options = jsonb_build_object(
  'en', options,
  'hu', '[]'::jsonb
)
WHERE jsonb_typeof(options) = 'array';

-- 5. Add indexes for language-specific searches
CREATE INDEX IF NOT EXISTS idx_questions_text_en ON questions(question_text_en);
CREATE INDEX IF NOT EXISTS idx_questions_text_hu ON questions(question_text_hu);

-- 6. Add comments for documentation
COMMENT ON COLUMN questions.question_text_en IS 'Question text in English';
COMMENT ON COLUMN questions.question_text_hu IS 'Question text in Hungarian';
COMMENT ON COLUMN questions.explanation_en IS 'Explanation in English';
COMMENT ON COLUMN questions.explanation_hu IS 'Explanation in Hungarian';
COMMENT ON COLUMN questions.options IS 'Options in multiple languages: {"en": [...], "hu": [...]}';
