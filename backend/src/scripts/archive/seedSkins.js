const db = require('../config/db');

async function seedSkins() {
    try {
        console.log('Seeding Bean Skins...');

        // 1. Skin Colors (Slot: skin_color, Type: skin)
        await db.query(`
      INSERT INTO items (name, type, slot_type, price, asset_path, description, theme)
      VALUES 
      ('Blue Bean', 'skin', 'skin_color', 50, 'assets/skins/bean_blue.png', 'A cool blue look.', 'clinical'),
      ('Green Bean', 'skin', 'skin_color', 50, 'assets/skins/bean_green.png', 'Healthy green.', 'clinical'),
      ('Pink Bean', 'skin', 'skin_color', 50, 'assets/skins/bean_pink.png', 'Rosy complexion.', 'cozy')
    `);

        // 2. Body Items (Slot: body, Type: skin)
        await db.query(`
      INSERT INTO items (name, type, slot_type, price, asset_path, description, theme)
      VALUES 
      ('Lab Coat', 'skin', 'body', 100, 'assets/skins/body_labcoat.png', 'Professional attire.', 'clinical'),
      ('Scrubs (Teal)', 'skin', 'body', 80, 'assets/skins/body_scrubs_teal.png', 'Comfortable scrubs.', 'clinical'),
      ('Hoodie', 'skin', 'body', 60, 'assets/skins/body_hoodie.png', 'Casual studying.', 'cozy')
    `);

        // 3. Head Items (Slot: head, Type: skin)
        await db.query(`
      INSERT INTO items (name, type, slot_type, price, asset_path, description, theme)
      VALUES 
      ('Surgical Cap', 'skin', 'head', 40, 'assets/skins/head_cap.png', 'Ready for surgery.', 'clinical'),
      ('Glasses', 'skin', 'head', 30, 'assets/skins/head_glasses.png', 'Boosts intelligence.', 'modern'),
      ('Party Hat', 'skin', 'head', 20, 'assets/skins/head_party.png', 'Celebrate your streak.', 'fun')
    `);

        console.log('Skins seeded successfully.');
    } catch (err) {
        console.error('Seeding skins failed:', err);
    } finally {
        await db.pool.end();
    }
}

seedSkins();
