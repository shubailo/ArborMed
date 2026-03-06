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
            { id: 200, name: 'Oak Starter Desk', type: 'furniture', slot_type: 'desk', price: 100, asset_path: 'assets/images/furniture/desk_0.webp', description: 'Sturdy and reliable.', theme: 'classic' },
            { id: 201, name: 'Minimalist White', type: 'furniture', slot_type: 'desk', price: 100, asset_path: 'assets/images/furniture/desk_1.webp', description: 'Clean lines for a clear mind.', theme: 'modern' },
            { id: 202, name: 'Mahogany Executive', type: 'furniture', slot_type: 'desk', price: 100, asset_path: 'assets/images/furniture/desk_2.webp', description: 'Serious business.', theme: 'executive' },
            { id: 203, name: 'Gamer Station', type: 'furniture', slot_type: 'desk', price: 100, asset_path: 'assets/images/furniture/desk_3.webp', description: 'RGB increases performance by 10%.', theme: 'gamer' },
            { id: 204, name: 'Standing Desk Pro', type: 'furniture', slot_type: 'desk', price: 150, asset_path: 'assets/images/furniture/desk_4.webp', description: 'Health-conscious workspace.', theme: 'modern' },

            // 🏥 CLINICAL (Gurneys / Exam Tables)
            { id: 400, name: 'Basic Exam Bed', type: 'furniture', slot_type: 'exam_table', price: 150, asset_path: 'assets/images/furniture/gurney_0.webp', description: 'Standard issue.', theme: 'clinical' },
            { id: 401, name: 'Advanced Gurney', type: 'furniture', slot_type: 'exam_table', price: 150, asset_path: 'assets/images/furniture/gurney_1.webp', description: 'With hydraulic lift support.', theme: 'clinical' },
            { id: 402, name: 'Premium Gurney', type: 'furniture', slot_type: 'exam_table', price: 200, asset_path: 'assets/images/furniture/gurney_2.webp', description: 'Top-of-the-line patient care.', theme: 'clinical' },
            { id: 403, name: 'Emergency Gurney', type: 'furniture', slot_type: 'exam_table', price: 250, asset_path: 'assets/images/furniture/gurney_3.webp', description: 'Built for rapid response.', theme: 'clinical' },

            // 💻 COMPUTERS (Monitors)
            { id: 500, name: 'Basic Monitor', type: 'furniture', slot_type: 'monitor', price: 75, asset_path: 'assets/images/furniture/computer_0.webp', description: 'For patient records.', theme: 'utilitarian' },
            { id: 501, name: 'Widescreen Display', type: 'furniture', slot_type: 'monitor', price: 100, asset_path: 'assets/images/furniture/computer_1.webp', description: 'Crystal clear imaging.', theme: 'modern' },
            { id: 502, name: 'Dual Monitor Setup', type: 'furniture', slot_type: 'monitor', price: 150, asset_path: 'assets/images/furniture/computer_2.webp', description: 'Maximum productivity.', theme: 'executive' },
            { id: 503, name: 'Gaming Rig', type: 'furniture', slot_type: 'monitor', price: 200, asset_path: 'assets/images/furniture/computer_3.webp', description: 'For after-hours relaxation.', theme: 'gamer' },

            // 🗄️ CORNER CABINETS
            { id: 600, name: 'Simple Shelf', type: 'furniture', slot_type: 'wall_decor', price: 75, asset_path: 'assets/images/furniture/cornercabinet_0.webp', description: 'Neat and tidy storage.', theme: 'classic' },
            { id: 601, name: 'Medicine Cabinet', type: 'furniture', slot_type: 'wall_decor', price: 100, asset_path: 'assets/images/furniture/cornercabinet_1.webp', description: 'Essential supplies at hand.', theme: 'clinical' },
            { id: 602, name: 'Bookshelf', type: 'furniture', slot_type: 'wall_decor', price: 100, asset_path: 'assets/images/furniture/cornercabinet_2.webp', description: 'Knowledge within reach.', theme: 'cozy' },
            { id: 603, name: 'Display Cabinet', type: 'furniture', slot_type: 'wall_decor', price: 125, asset_path: 'assets/images/furniture/cornercabinet_3.webp', description: 'Show off your achievements.', theme: 'modern' },
            { id: 604, name: 'Trophy Case', type: 'furniture', slot_type: 'wall_decor', price: 150, asset_path: 'assets/images/furniture/cornercabinet_4.webp', description: 'For the distinguished physician.', theme: 'executive' },

            // 🧶 RUGS
            { id: 700, name: 'Cozy Rug', type: 'furniture', slot_type: 'desk_decor', price: 50, asset_path: 'assets/images/furniture/rug_0.webp', description: 'Warm underfoot.', theme: 'cozy' },
            { id: 701, name: 'Modern Rug', type: 'furniture', slot_type: 'desk_decor', price: 75, asset_path: 'assets/images/furniture/rug_1.webp', description: 'Geometric patterns.', theme: 'modern' },
            { id: 702, name: 'Persian Rug', type: 'furniture', slot_type: 'desk_decor', price: 100, asset_path: 'assets/images/furniture/rug_2.webp', description: 'Timeless elegance.', theme: 'classic' },
            { id: 703, name: 'Minimalist Mat', type: 'furniture', slot_type: 'desk_decor', price: 50, asset_path: 'assets/images/furniture/rug_3.webp', description: 'Less is more.', theme: 'modern' },
        ];

        console.log(`📦 Batch inserting ${items.length} items...`);
        // Optimization: Use a single batch INSERT instead of a loop to avoid N+1 query overhead.
        // This reduces I/O roundtrips from O(N) to O(1).
        const values = [];
        const placeholders = items
            .map((item, i) => {
                const offset = i * 8;
                values.push(
                    item.id,
                    item.name,
                    item.type,
                    item.slot_type,
                    item.price,
                    item.asset_path,
                    item.description,
                    item.theme,
                );
                return `($${offset + 1}, $${offset + 2}, $${offset + 3}, $${offset + 4}, $${offset + 5}, $${offset + 6}, $${offset + 7}, $${offset + 8})`;
            })
            .join(', ');

        await db.query(
            `
                INSERT INTO items (id, name, type, slot_type, price, asset_path, description, theme)
                VALUES ${placeholders}
            `,
            values,
        );

        await db.query("SELECT setval(pg_get_serial_sequence('items', 'id'), (SELECT MAX(id) FROM items))");

        console.log('✨ Gold Catalog restoration complete.');
        process.exit();
    } catch (err) {
        console.error('❌ Seeding failed:', err);
        process.exit(1);
    }
}

seedGoldCatalog();
