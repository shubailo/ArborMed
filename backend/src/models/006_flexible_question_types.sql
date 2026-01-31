-- Migration: 006_flexible_question_types.sql
-- Purpose: Add support for multiple question types with flexible content structure

-- 1. Add new columns to questions table
ALTER TABLE questions 
ADD COLUMN IF NOT EXISTS question_type VARCHAR(50) DEFAULT 'single_choice',
ADD COLUMN IF NOT EXISTS content JSONB,
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

-- 2. Migrate existing questions to new format
-- Single choice questions
UPDATE questions 
SET 
  question_type = CASE 
    WHEN type = 'single_choice' THEN 'single_choice'
    WHEN type = 'multiple_choice' THEN 'multiple_choice'
    WHEN type = 'ecg' THEN 'ecg'
    WHEN type = 'case_study' THEN 'case_study'
    ELSE 'single_choice'
  END,
  content = jsonb_build_object(
    'question_text', text,
    'options', CASE 
      WHEN jsonb_typeof(options) = 'array' THEN options
      ELSE to_jsonb(ARRAY[options]::text[])
    END
  ),
  metadata = jsonb_build_object(
    'difficulty', difficulty,
    'created_at', created_at
  )
WHERE content IS NULL;

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_questions_type ON questions(question_type);
CREATE INDEX IF NOT EXISTS idx_questions_content ON questions USING GIN(content);
CREATE INDEX IF NOT EXISTS idx_questions_metadata ON questions USING GIN(metadata);

-- 4. Add comment for documentation
COMMENT ON COLUMN questions.question_type IS 'Type of question: single_choice, multiple_choice, relation_analysis, matching, true_false, etc.';
COMMENT ON COLUMN questions.content IS 'Type-specific content structure stored as JSON';
COMMENT ON COLUMN questions.metadata IS 'Additional metadata like time limits, point values, tags, etc.';
