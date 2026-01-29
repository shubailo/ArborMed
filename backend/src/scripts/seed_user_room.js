const db = require('../config/db');

const seed = async () => {
    try {
        console.log('🔍 Checking Users...');
        const users = await db.query('SELECT id, email FROM users ORDER BY id ASC LIMIT 1');

        if (users.rows.length === 0) {
            console.log('❌ No users found! Cannot seed room.');
            process.exit(1);
        }

        const userId = users.rows[0].id;
        console.log(`✅ Found User ID: ${userId} (${users.rows[0].email})`);

        console.log('🌱 Seeding Default Room...');

        // Insert room if not exists
        const roomRes = await db.query(`
            INSERT INTO user_rooms (id, user_id, room_type, is_active)
            VALUES (1, $1, 'exam', TRUE)
            ON CONFLICT (user_id, room_type) DO UPDATE SET is_active = TRUE
            RETURNING id;
        `, [userId]); // Forcing ID 1 if possible, but serial might ignore. 
        // Actually, explicit insert of ID works in Postgres if not colliding.
        // But better to just let serial work if table is empty.
        // Wait, if I want ID 1 for frontend hardcoding, I should try to force it or update sequence.

        // Let's try forcing ID 1 since table is empty.

        console.log(`✅ Room Created/Updated with ID: ${roomRes.rows[0].id}`);

        process.exit();
    } catch (e) {
        console.error('❌ Error seeding room:', e);
        process.exit(1);
    }
};

seed();
