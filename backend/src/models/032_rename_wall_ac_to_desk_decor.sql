-- Rename slot_type in global items catalog
UPDATE items 
SET slot_type = 'desk_decor',
    name = CASE 
        WHEN name = 'Standard AC' THEN 'Modern Workstation'
        WHEN name = 'Industrial Climate Control' THEN 'Advanced Terminal'
        ELSE name 
    END,
    description = CASE 
        WHEN description = 'Keeps the room cool.' THEN 'A high-performance system for medical data.'
        WHEN description = 'Hospital-grade air filtration.' THEN 'Professional-grade processing power.'
        ELSE description 
    END
WHERE slot_type = 'wall_ac';

-- Rename slot_type in user inventory to maintain placement
UPDATE user_items 
SET placed_at_slot = 'desk_decor' 
WHERE placed_at_slot = 'wall_ac';
