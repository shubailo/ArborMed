const db = require('../config/db');

async function seedBaseFurniture() {
    try {
        console.log('Seeding BASE furniture items...');

        const items = [
            // DESKS
            { name: 'Modern Glass Desk', type: 'equipment', slot_type: 'desk', price: 120, asset_path: 'assets/images/furniture/desk.png', description: 'A sleek, professional workstation for modern clinics.', theme: 'clinical' },
            { name: 'Classic Oak Desk', type: 'equipment', slot_type: 'desk', price: 90, asset_path: 'assets/images/furniture/desk_1.png', description: 'Reliable and sturdy wooden desk for traditional doctors.', theme: 'vintage' },
            { name: 'Hospital Station', type: 'equipment', slot_type: 'desk', price: 150, asset_path: 'assets/images/furniture/desk_2.png', description: 'Standard hospital grade desk with built-in cable management.', theme: 'clinical' },

            // EXAM TABLES
            { name: 'Blue Gurney', type: 'equipment', slot_type: 'exam_table', price: 200, asset_path: 'assets/images/furniture/gurey_1.png', description: 'Standard patient mobility bed.', theme: 'clinical' },
            { name: 'Advanced Hydraulic Table', type: 'equipment', slot_type: 'exam_table', price: 350, asset_path: 'assets/images/furniture/gurey_2.png', description: 'Adjustable height for easier patient examinations.', theme: 'clinical' },
            { name: 'Comfort Exam Bed', type: 'equipment', slot_type: 'exam_table', price: 180, asset_path: 'assets/images/furniture/gurey_3.png', description: 'High-comfort bed for patient recovery.', theme: 'clinical' },

            // CHAIRS
            { name: 'Patient Stool', type: 'equipment', slot_type: 'chair', price: 50, asset_path: 'assets/items/patient_stool.png', description: 'Compact and efficient stool for patients.', theme: 'clinical' },
            { name: 'Ergo Doctor Chair', type: 'equipment', slot_type: 'chair', price: 110, asset_path: 'assets/items/doctor_chair.png', description: 'Maximum comfort for those long shifts.', theme: 'clinical' },
            { name: 'Waiting Sofa', type: 'equipment', slot_type: 'chair', price: 140, asset_path: 'assets/items/sofa.png', description: 'Add comfort to your patient lounge.', theme: 'cozy' },

            // STORAGE
            { name: 'Filing Cabinet', type: 'equipment', slot_type: 'storage', price: 80, asset_path: 'assets/items/cabinet.png', description: 'Keep your patient records organized.', theme: 'clinical' },
            { name: 'Medical Cabinet', type: 'equipment', slot_type: 'storage', price: 220, asset_path: 'assets/items/med_cabinet.png', description: 'Secure storage for vaccines and supplies.', theme: 'clinical' },
            { name: 'Bookshelf', type: 'equipment', slot_type: 'storage', price: 100, asset_path: 'assets/items/bookshelf.png', description: 'Show off your medical textbook collection.', theme: 'clinical' },
        ];

        for (const item of items) {
            // Check if item exists
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

        console.log('Base Furniture seeding check complete.');
    } catch (err) {
        console.error('Seeding failed:', err);
    } finally {
        await db.pool.end();
    }
}

seedBaseFurniture();
