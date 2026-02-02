const db = require('../config/db');

async function seedHighFidelity() {
    try {
        console.log('🧬 Seeding HIGH-FIDELITY medical furniture...');

        const items = [
            {
                name: 'Vital Monitor stand',
                type: 'equipment',
                slot_type: 'monitor',
                price: 180,
                asset_path: 'assets/images/furniture/monitor.png',
                description: 'Real-time vital signs monitoring for critical patients.',
                theme: 'clinical'
            },
            {
                name: 'Silver Trash Bin',
                type: 'equipment',
                slot_type: 'bin',
                price: 30,
                asset_path: 'assets/images/furniture/bin.png',
                description: 'Pure stainless steel disposal unit with foot pedal.',
                theme: 'clinical'
            },
            {
                name: 'Medical Potted Plant',
                type: 'decoration',
                slot_type: 'plant',
                price: 45,
                asset_path: 'assets/images/furniture/plant.png',
                description: 'A touch of green to improve patient air quality.',
                theme: 'clinical'
            },
            {
                name: 'Wall-mounted AC Unit',
                type: 'equipment',
                slot_type: 'wall_ac',
                price: 250,
                asset_path: 'assets/images/furniture/ac.png',
                description: 'High-efficiency climate control for clean rooms.',
                theme: 'clinical'
            },
            {
                name: 'Medical Wall Calendar',
                type: 'decoration',
                slot_type: 'wall_calendar',
                price: 20,
                asset_path: 'assets/images/furniture/calendar.png',
                description: 'Track patient appointments and medical milestones.',
                theme: 'clinical'
            }
        ];

        for (const item of items) {
            const existing = await db.query('SELECT id FROM items WHERE name = $1', [item.name]);
            if (existing.rowCount === 0) {
                await db.query(`
                    INSERT INTO items (name, type, slot_type, price, asset_path, description, theme)
                    VALUES ($1, $2, $3, $4, $5, $6, $7)
                `, [item.name, item.type, item.slot_type, item.price, item.asset_path, item.description, item.theme]);
                console.log(`Added: ${item.name}`);
            } else {
                console.log(`Skipped (exists): ${item.name}`);
            }
        }

        console.log('✅ High-Fidelity seeding complete.');
        process.exit();
    } catch (err) {
        console.error('Seeding failed:', err);
        process.exit(1);
    }
}

seedHighFidelity();
