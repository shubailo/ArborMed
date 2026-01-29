const db = require('../config/db');

async function seedFurniture() {
    try {
        console.log('Seeding Clinic Furniture...');

        // Furniture Items (Slot: floor)
        await db.query(`
      INSERT INTO items (name, type, slot_type, price, asset_path, description, theme)
      VALUES 
      ('Exam Table', 'equipment', 'floor', 150, 'assets/items/exam_table.png', 'A sleek modern examination table.', 'clinical'),
      ('Medical Bookshelf', 'equipment', 'floor', 120, 'assets/items/bookshelf.png', 'Perfect for medical textbooks.', 'clinical'),
      ('Microscope Station', 'equipment', 'floor', 200, 'assets/items/microscope.png', 'High-tech researcher setup.', 'clinical'),
      ('Coat Rack', 'equipment', 'floor', 45, 'assets/items/coat_rack.png', 'Displays your extra lab coats.', 'clinical'),
      ('Monstera Plant', 'decor', 'floor', 60, 'assets/items/plant.png', 'Medicinal greenery.', 'cozy'),
      ('Espresso Machine', 'decor', 'floor', 80, 'assets/items/espresso.png', 'For 4 AM study sprints.', 'cozy'),
      ('Cross Rug', 'decor', 'floor', 40, 'assets/items/rug.png', 'Soft clinic rug.', 'cozy')
    `);

        console.log('Furniture seeded successfully.');
    } catch (err) {
        console.error('Seeding furniture failed:', err);
    } finally {
        await db.pool.end();
    }
}

seedFurniture();
