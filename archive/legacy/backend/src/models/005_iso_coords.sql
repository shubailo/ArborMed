-- Add grid coordinates to user_items for Isometric placement
ALTER TABLE user_items 
ADD COLUMN x_pos INTEGER DEFAULT 0,
ADD COLUMN y_pos INTEGER DEFAULT 0;
