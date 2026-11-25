CREATE TABLE crate_purchases (
    user_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    purchase_id varchar(128) NOT NULL,
    crate_id text NOT NULL,
    result jsonb NOT NULL,
    PRIMARY KEY(user_id, purchase_id)
);
ALTER TABLE crate_purchases ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON crate_purchases FROM PUBLIC;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON items, user_items FROM PUBLIC;
DO $$
DECLARE client_role text;
BEGIN
    FOREACH client_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = client_role) THEN
            EXECUTE format('REVOKE ALL ON crate_purchases FROM %I', client_role);
            EXECUTE format('REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON items, user_items FROM %I', client_role);
        END IF;
    END LOOP;
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'med_buddy_app') THEN
        GRANT SELECT, INSERT ON crate_purchases TO med_buddy_app;
        CREATE POLICY backend_crate_purchases ON crate_purchases TO med_buddy_app USING (true) WITH CHECK (true);
    END IF;
END $$;

-- Earlier clients stored fixed slots at (0, 0). Keep those slots and any unambiguous grid coordinates.
ALTER TABLE user_items ADD COLUMN uses_grid boolean NOT NULL DEFAULT false;
UPDATE user_items SET uses_grid = true WHERE is_placed AND (x_pos <> 0 OR y_pos <> 0 OR placed_at_slot = 'floor');
UPDATE user_items ui SET is_placed = false, placed_at_room_id = NULL, placed_at_slot = NULL, uses_grid = false
WHERE (is_placed OR placed_at_room_id IS NOT NULL)
  AND NOT EXISTS (SELECT FROM user_rooms r WHERE r.id = ui.placed_at_room_id AND r.user_id = ui.user_id);
WITH ranked AS (
    SELECT id, row_number() OVER (
        PARTITION BY placed_at_room_id, uses_grid, CASE WHEN NOT uses_grid THEN placed_at_slot END,
            CASE WHEN uses_grid THEN x_pos END, CASE WHEN uses_grid THEN y_pos END
        ORDER BY id DESC
    ) AS rn FROM user_items WHERE is_placed
)
UPDATE user_items SET is_placed = false, placed_at_room_id = NULL, placed_at_slot = NULL, uses_grid = false
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);
CREATE UNIQUE INDEX user_items_fixed_slot ON user_items(placed_at_room_id, placed_at_slot) WHERE is_placed AND NOT uses_grid;
CREATE UNIQUE INDEX user_items_grid_cell ON user_items(placed_at_room_id, x_pos, y_pos) WHERE is_placed AND uses_grid;
ALTER TABLE user_rooms ADD CONSTRAINT user_rooms_owner_key UNIQUE(id, user_id);
ALTER TABLE user_items DROP CONSTRAINT user_items_placed_at_room_id_fkey;
ALTER TABLE user_items ADD CONSTRAINT user_items_room_owner_fkey FOREIGN KEY(placed_at_room_id, user_id)
    REFERENCES user_rooms(id, user_id);
CREATE FUNCTION unplace_room_inventory() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    UPDATE user_items SET is_placed = false, placed_at_room_id = NULL, placed_at_slot = NULL, uses_grid = false
    WHERE placed_at_room_id = OLD.id;
    RETURN OLD;
END $$;
CREATE TRIGGER unplace_before_room_delete BEFORE DELETE ON user_rooms FOR EACH ROW EXECUTE FUNCTION unplace_room_inventory();

-- Retain historical records while enforcing valid participants for every new like.
ALTER TABLE room_likes ADD CONSTRAINT room_likes_participants CHECK (
    liker_id IS NOT NULL AND receiver_id IS NOT NULL AND liker_id <> receiver_id
) NOT VALID;
ALTER TABLE room_likes ADD CONSTRAINT room_likes_liker_fk FOREIGN KEY(liker_id) REFERENCES users(id) ON DELETE CASCADE NOT VALID;
ALTER TABLE room_likes ADD CONSTRAINT room_likes_receiver_fk FOREIGN KEY(receiver_id) REFERENCES users(id) ON DELETE CASCADE NOT VALID;
