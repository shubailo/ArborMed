-- Occupancy indexes can only protect placements with complete keys.
-- Apply this invariant to new writes while allowing historical rows to be repaired.
ALTER TABLE user_items ADD CONSTRAINT user_items_placed_requires_location CHECK (
    is_placed IS NOT TRUE OR (
        placed_at_room_id IS NOT NULL
        AND placed_at_slot IS NOT NULL AND btrim(placed_at_slot) <> ''
        AND (NOT uses_grid OR (x_pos IS NOT NULL AND y_pos IS NOT NULL))
    )
) NOT VALID;
