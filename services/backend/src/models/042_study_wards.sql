-- Migration: Study Wards Feature
-- Adds tables to support collaborative multiplayer study sessions.

CREATE TABLE IF NOT EXISTS wards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(6) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  host_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS ward_members (
  ward_id UUID REFERENCES wards(id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ward_id, user_id)
);

CREATE TABLE IF NOT EXISTS ward_inventory (
  ward_id UUID REFERENCES wards(id) ON DELETE CASCADE,
  item_id INTEGER NOT NULL, -- Logical reference to a catalog of items (not enforced via FK to keep it flexible for now)
  acquired_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ward_id, item_id)
);

-- Index for quick lookups
CREATE INDEX IF NOT EXISTS idx_wards_code ON wards(code);
CREATE INDEX IF NOT EXISTS idx_ward_members_user ON ward_members(user_id);
