const db = require('../config/db');
require('dotenv').config();

const seedGamification = async () => {
    try {
        console.log('🌱 Seeding Gamification Data...');

        // 1. Items (Equipment & Decor)
        // Note: asset_paths are placeholders for now.
        const items = [
            // Floor Items
            { name: 'Potted Plant', type: 'decor', slot: 'floor_left', price: 200, asset: 'plant_1.png' },
            { name: 'Anatomical Skeleton', type: 'decor', slot: 'floor_right', price: 500, asset: 'skeleton.png' },
            { name: 'Persian Rug', type: 'decor', slot: 'floor_left', price: 300, asset: 'rug_persian.png' },

            // Wall Items
            { name: 'Medical Diploma', type: 'decor', slot: 'wall', price: 1000, asset: 'diploma.png' },
            { name: 'X-Ray Lightbox', type: 'equipment', slot: 'wall', price: 1500, asset: 'xray_box.png' },
            { name: 'Anatomy Poster', type: 'decor', slot: 'wall', price: 150, asset: 'poster_anatomy.png' },

            // Desk Items
            { name: 'Golden Stethoscope', type: 'equipment', slot: 'desk', price: 2000, asset: 'steth_gold.png' },
            { name: 'Vintage Microscope', type: 'equipment', slot: 'desk', price: 1200, asset: 'microscope.png' },
            { name: 'Study Lamp', type: 'decor', slot: 'desk', price: 100, asset: 'lamp.png' },

            // Ceiling Items
            { name: 'Surgical Light', type: 'equipment', slot: 'ceiling', price: 2500, asset: 'light_surgical.png' }
        ];

        for (const item of items) {
            await db.query(
                `INSERT INTO items (name, type, slot_type, price, asset_path) 
         VALUES ($1, $2, $3, $4, $5)`,
                [item.name, item.type, item.slot, item.price, item.asset]
            );
        }
        console.log(`✅ Inserted ${items.length} Shop Items.`);

        // 2. We don't necessarily need a "rooms" table if "room_type" in user_rooms is an enum/string.
        // The previous design implies we just unlock strings ('cardio', 'neuro').
        // So no Room seeding needed, logic will handled in the API (unlocking a room string).

        console.log('Gamification Seed successful!');
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

seedGamification();
