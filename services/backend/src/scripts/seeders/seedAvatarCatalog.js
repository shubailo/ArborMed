const db = require('../../config/db');

async function seedAvatarCatalog() {
    try {
        console.log('🌟 Seeding Avatar Creator Assets...');

        const items = [
            // 💇 HAIR
            { id: 1000, name: 'Bald', type: 'avatar', slot_type: 'hair', price: 0, is_free: true, theme: 'neutral' },
            { id: 1001, name: 'Short Flat', type: 'avatar', slot_type: 'hair', price: 0, is_free: true, theme: 'casual' },
            { id: 1002, name: 'Long Straight', type: 'avatar', slot_type: 'hair', price: 100, is_free: false, theme: 'formal' },

            // 👁️ EYES
            { id: 1100, name: 'Standard Eyes', type: 'avatar', slot_type: 'eyes', price: 0, is_free: true, theme: 'neutral' },
            { id: 1101, name: 'Happy Eyes', type: 'avatar', slot_type: 'eyes', price: 0, is_free: true, theme: 'neutral' },
            { id: 1102, name: 'Closed Eyes', type: 'avatar', slot_type: 'eyes', price: 50, is_free: false, theme: 'chill' },
            { id: 1103, name: 'Crying Eyes', type: 'avatar', slot_type: 'eyes', price: 50, is_free: false, theme: 'emotional' },

            // 👄 MOUTH
            { id: 1200, name: 'Neutral Mouth', type: 'avatar', slot_type: 'mouth', price: 0, is_free: true, theme: 'neutral' },
            { id: 1201, name: 'Smile', type: 'avatar', slot_type: 'mouth', price: 0, is_free: true, theme: 'neutral' },
            { id: 1202, name: 'Sad Mouth', type: 'avatar', slot_type: 'mouth', price: 0, is_free: true, theme: 'neutral' },

            // 🤨 EYEBROWS
            { id: 1300, name: 'Standard Brows', type: 'avatar', slot_type: 'eyebrows', price: 0, is_free: true, theme: 'neutral' },
            { id: 1301, name: 'Angry Brows', type: 'avatar', slot_type: 'eyebrows', price: 0, is_free: true, theme: 'agressive' },

            // 👕 OUTFIT
            { id: 1400, name: 'Basic Hoodie', type: 'avatar', slot_type: 'outfit', price: 0, is_free: true, theme: 'casual' },
            { id: 1401, name: 'Business Blazer', type: 'avatar', slot_type: 'outfit', price: 150, is_free: false, theme: 'formal' },

            // 🕶️ ACCESSORIES
            { id: 1500, name: 'Nothing', type: 'avatar', slot_type: 'accessory', price: 0, is_free: true, theme: 'none' },
            { id: 1501, name: 'Smart Glasses', type: 'avatar', slot_type: 'accessory', price: 75, is_free: false, theme: 'student' },
        ];

        console.log(`📦 Batch inserting ${items.length} avatar items...`);
        const values = [];
        const placeholders = items
            .map((item, i) => {
                const offset = i * 9;
                values.push(
                    item.id,
                    item.name,
                    item.type,
                    item.slot_type,
                    item.price,
                    item.is_free,
                    'none', // asset_path not used for SVG layers
                    'Standard item', // description
                    item.theme,
                );
                return `($${offset + 1}, $${offset + 2}, $${offset + 3}, $${offset + 4}, $${offset + 5}, $${offset + 6}, $${offset + 7}, $${offset + 8}, $${offset + 9})`;
            })
            .join(', ');

        await db.query(
            `
                INSERT INTO items (id, name, type, slot_type, price, is_free, asset_path, description, theme)
                VALUES ${placeholders}
                ON CONFLICT (id) DO UPDATE SET
                    name = EXCLUDED.name,
                    price = EXCLUDED.price,
                    is_free = EXCLUDED.is_free,
                    theme = EXCLUDED.theme
            `,
            values,
        );

        console.log('✨ Avatar Catalog seeding complete.');
    } catch (err) {
        console.error('❌ Seeding failed:', err);
    }
}

module.exports = seedAvatarCatalog;
