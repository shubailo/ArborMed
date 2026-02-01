-- Migration: 014_localize_quiz_entities.sql
-- Purpose: Add Hungarian language support for topics and quotes

-- 1. Localize Topics
ALTER TABLE topics 
RENAME COLUMN name TO name_en;

ALTER TABLE topics 
ADD COLUMN name_hu VARCHAR(100) DEFAULT '';

-- 2. Localize Quotes
ALTER TABLE quotes 
RENAME COLUMN text TO text_en;

ALTER TABLE quotes 
ADD COLUMN text_hu TEXT DEFAULT '';

-- Update existing Hungarian fields with English content as fallback (as per user request 1)
UPDATE topics SET name_hu = name_en WHERE name_hu = '';
UPDATE quotes SET text_hu = text_en WHERE text_hu = '';

-- Add comments for documentation
COMMENT ON COLUMN topics.name_en IS 'Topic name in English';
COMMENT ON COLUMN topics.name_hu IS 'Topic name in Hungarian';
COMMENT ON COLUMN quotes.text_en IS 'Quote text in English';
COMMENT ON COLUMN quotes.text_hu IS 'Quote text in Hungarian';
