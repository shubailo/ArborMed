-- Phase 1 of Residency Hub: Rank & Progression
ALTER TABLE users ADD COLUMN IF NOT EXISTS rank VARCHAR(50) DEFAULT 'unmatched';
ALTER TABLE users ADD COLUMN IF NOT EXISTS malpractice_strikes INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_rounds_date DATE;

-- Ensure Rank matches our Clinical progression
-- unmatched -> intern -> resident -> attending -> chief
ALTER TABLE users DROP CONSTRAINT IF EXISTS check_rank_values;
ALTER TABLE users ADD CONSTRAINT check_rank_values CHECK (rank IN ('unmatched', 'intern', 'resident', 'attending', 'chief'));

-- Index for analytics
CREATE INDEX IF NOT EXISTS idx_users_rank ON users(rank);
