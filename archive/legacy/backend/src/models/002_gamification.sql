-- Items Catalog (Global)
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'equipment', 'decor', 'wall'
    slot_type VARCHAR(50) NOT NULL, -- 'floor_left', 'floor_right', 'desk', 'wall', 'ceiling'
    price INTEGER NOT NULL DEFAULT 0,
    asset_path VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User's Unlocked Rooms
CREATE TABLE user_rooms (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    room_type VARCHAR(50) NOT NULL, -- 'exam', 'cardio', 'neuro'
    is_active BOOLEAN DEFAULT FALSE, -- Which room is currently displayed
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, room_type)
);

-- User's Owned Items (Inventory & Placement)
CREATE TABLE user_items (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    item_id INTEGER REFERENCES items(id) ON DELETE CASCADE,
    is_placed BOOLEAN DEFAULT FALSE,
    placed_at_room_id INTEGER REFERENCES user_rooms(id) ON DELETE CASCADE,
    placed_at_slot VARCHAR(50), -- Only relevant if placed
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
