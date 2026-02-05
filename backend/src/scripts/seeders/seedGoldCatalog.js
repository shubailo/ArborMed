const db = require('../../config/db');

async function seedGoldCatalog() {
    try {
        console.log('🌟 Seeding GOLD High-Fidelity Catalog...');

        console.log('🧹 Clearing old items...');
        await db.query('TRUNCATE items CASCADE');

        const items = [
            // 🏠 ROOMS
            { id: 100, name: 'Cozy Morning', type: 'room', slot_type: 'room', price: 0, asset_path: 'assets/images/room/room_0.webp', description: 'A bright, sun-filled room perfect for early risers.', theme: 'cozy' },
            { id: 101, name: 'Midnight Study', type: 'room', slot_type: 'room', price: 500, asset_path: 'assets/images/room/room_1.webp', description: 'Deep calm tones for focused night sessions.', theme: 'dark' },

            // 🪑 FURNITURE (Desks)
            { id: 200, name: 'Oak Starter Desk', type: 'furniture', slot_type: 'desk', price: 100, asset_path: 'assets/images/furniture/desk.webp', description: 'Sturdy and reliable.', theme: 'classic' },
            { id: 201, name: 'Minimalist White', type: 'furniture', slot_type: 'desk', price: 100, asset_path: 'assets/images/furniture/desk_1.webp', description: 'Clean lines for a clear mind.', theme: 'modern' },
            { id: 202, name: 'Mahogany Executive', type: 'furniture', slot_type: 'desk', price: 100, asset_path: 'assets/images/furniture/desk_2.webp', description: 'Serious business.', theme: 'executive' },
            { id: 203, name: 'Gamer Station', type: 'furniture', slot_type: 'desk', price: 100, asset_path: 'assets/images/furniture/desk_3.webp', description: 'RGB increases performance by 10%.', theme: 'gamer' },

            // ❄️ WALL (AC / Climate)
            { id: 300, name: 'Standard AC', type: 'furniture', slot_type: 'wall_ac', price: 75, asset_path: 'assets/images/furniture/ac.webp', description: 'Keeps the room cool.', theme: 'utilitarian' },
            { id: 301, name: 'Industrial Climate Control', type: 'furniture', slot_type: 'wall_ac', price: 75, asset_path: 'assets/images/furniture/ac_1.webp', description: 'Hospital-grade air filtration.', theme: 'clinical' },

            // 🏥 CLINICAL (Gurneys / Exam Tables)
            { id: 400, name: 'Basic Exam Bed', type: 'furniture', slot_type: 'exam_table', price: 150, asset_path: 'assets/images/furniture/gurey_1.webp', description: 'Standard issue.', theme: 'clinical' },
            { id: 401, name: 'Advanced Gurney', type: 'furniture', slot_type: 'exam_table', price: 150, asset_path: 'assets/images/furniture/gurey_2.webp', description: 'With hydraulic lift support.', theme: 'clinical' },

            // 🎨 DECOR (Wall)
            { id: 500, name: 'Geometric Wall Art', type: 'furniture', slot_type: 'wall_decor', price: 75, asset_path: 'assets/images/furniture/wall_decor.webp', description: 'Adds a splash of color to the clinic.', theme: 'modern' },

            // 🪟 WINDOWS
            { id: 600, name: 'Sunny Window', type: 'furniture', slot_type: 'window', price: 200, asset_path: 'assets/images/furniture/window.webp', description: 'Let the sunshine in.', theme: 'cozy' },
        ];

        for (const item of items) {
            await db.query(`
                INSERT INTO items (id, name, type, slot_type, price, asset_path, description, theme)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            `, [item.id, item.name, item.type, item.slot_type, item.price, item.asset_path, item.description, item.theme]);
            console.log(`✅ Added: ${item.name} (${item.price} coins)`);
        }

        await db.query("SELECT setval(pg_get_serial_sequence('items', 'id'), (SELECT MAX(id) FROM items))");

        console.log('✨ Gold Catalog restoration complete.');
        process.exit();
    } catch (err) {
        console.error('❌ Seeding failed:', err);
        process.exit(1);
    }
}

seedGoldCatalog();
