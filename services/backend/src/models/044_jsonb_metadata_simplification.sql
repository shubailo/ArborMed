-- 1. Expansion of core tables
ALTER TABLE questions ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';
ALTER TABLE topics ADD COLUMN IF NOT EXISTS nexus_metadata JSONB DEFAULT '{}';
ALTER TABLE responses ADD COLUMN IF NOT EXISTS stability DECIMAL DEFAULT 2.0;
ALTER TABLE responses ADD COLUMN IF NOT EXISTS difficulty DECIMAL DEFAULT 3.0;

-- 2. Data Migration: Prerequisites
-- Move data from the junction table to the JSONB column in 'questions'
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'question_prerequisites') THEN
        UPDATE questions q
        SET metadata = q.metadata || jsonb_build_object(
            'prerequisite_ids', 
            COALESCE((
                SELECT jsonb_agg(prerequisite_id) 
                FROM question_prerequisites 
                WHERE question_id = q.id
            ), '[]'::jsonb)
        );
    END IF;
END $$;

-- 3. Data Migration: Topic Nexus
-- Move data from the junction table to the JSONB column in 'topics'
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'topic_nexus') THEN
        UPDATE topics t
        SET nexus_metadata = t.nexus_metadata || jsonb_build_object(
            'nexus_links', 
            COALESCE((
                SELECT jsonb_agg(jsonb_build_object('topic_id', 
                    CASE WHEN topic_a_id = t.id THEN topic_b_id ELSE topic_a_id END,
                    'strength', correlation_strength))
                FROM topic_nexus 
                WHERE topic_a_id = t.id OR topic_b_id = t.id
            ), '[]'::jsonb)
        );
    END IF;
END $$;

-- 4. Cleanup: Only drop after successful migration verified by user or context check
-- Currently commented out for safety until the final cleanup task
-- DROP TABLE IF EXISTS question_prerequisites;
-- DROP TABLE IF EXISTS topic_nexus;

-- 5. Efficiency Indices
CREATE INDEX IF NOT EXISTS idx_questions_metadata_gin ON questions USING GIN (metadata);
CREATE INDEX IF NOT EXISTS idx_topics_nexus_gin ON topics USING GIN (nexus_metadata);
