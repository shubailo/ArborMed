-- Migration 026: Full-Text Search Optimization (Admin Pro)
-- Description: Add GIN indexes for sub-100ms full-text search on large datasets.

-- 1. Optimized Question Search
-- Enable pg_trgm extension if not already enabled (required for ILIKE optimization with GIN)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Index for searching questions by English text
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_questions_text_en_trgm 
ON public.questions USING gin (question_text_en gin_trgm_ops);

-- Index for searching topics by name
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_topics_name_en_trgm 
ON public.topics USING gin (name_en gin_trgm_ops);

-- 2. Optimized User Search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email_trgm 
ON public.users USING gin (email gin_trgm_ops);
