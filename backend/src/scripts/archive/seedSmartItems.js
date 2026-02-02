const db = require('../config/db');

async function seedSmartItems() {
    try {
        console.log('Seeding SMART items...');

        // 1. Cardio Wall Chart (Mastery Locked)
        await db.query(`
      INSERT INTO items (name, type, slot_type, price, asset_path, description, theme, unlock_req)
      VALUES 
      ('Cardio Chart', 'wall', 'wall', 150, 'assets/items/cardio_chart.png', 'Detailed anatomy of the heart.', 'clinical', '{"mastery": {"subject": "cardiovascular", "level": 3}}')
    `);

        // 2. Vintage Lamp (Themed)
        await db.query(`
      INSERT INTO items (name, type, slot_type, price, asset_path, description, theme)
      VALUES 
      ('Vintage Lamp', 'decor', 'desk', 75, 'assets/items/vintage_lamp.png', 'A classic brass lamp.', 'vintage')
    `);

        // 3. Neuro Poster (Mastery Locked)
        await db.query(`
      INSERT INTO items (name, type, slot_type, price, asset_path, description, theme, unlock_req)
      VALUES 
      ('Brain Map', 'wall', 'wall', 200, 'assets/items/brain_map.png', 'Complete map of cortical areas.', 'clinical', '{"mastery": {"subject": "neurology", "level": 2}}')
    `);

        console.log('Smart Items seeded successfully.');
    } catch (err) {
        console.error('Seeding failed:', err);
    } finally {
        await db.pool.end();
    }
}

seedSmartItems();
