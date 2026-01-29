const db = require('../config/db');

const debug = async () => {
    try {
        console.log('🔍 Inspecting user_rooms DATA...');

        const data = await db.query(`
            SELECT id, user_id, room_type, is_active 
            FROM user_rooms
            LIMIT 20;
        `);

        console.log(`✅ Found ${data.rows.length} rooms.`);
        console.table(data.rows);

        process.exit();
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
};

debug();
