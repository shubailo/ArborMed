-- Add Smart Shop Columns to Items
ALTER TABLE items 
ADD COLUMN theme VARCHAR(50), -- e.g. 'modern', 'vintage', 'cozy', 'clinical'
ADD COLUMN unlock_req JSONB,  -- e.g. {"mastery": {"subject": "cardiovascular", "level": 1}}
ADD COLUMN set_id INTEGER;    -- For future set bonuses

-- Update existing items with defaults
UPDATE items SET theme = 'clinical' WHERE theme IS NULL;
