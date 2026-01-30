const db = require('./backend/src/config/db');

async function createDefaultRoom() {
    try {
        // Get the user (assuming shubailobeid@gmail.com)
        const userResult = await db.query("SELECT id FROM users WHERE email = 'shubailobeid@gmail.com'");

        if (userResult.rows.length === 0) {
            console.log('❌ User not found');
            process.exit(1);
        }

        const userId = userResult.rows[0].id;
        console.log(`✅ Found user ID: ${userId}`);

        // Check if room already exists
        const roomCheck = await db.query("SELECT * FROM user_rooms WHERE user_id = $1", [userId]);

        if (roomCheck.rows.length > 0) {
            console.log(`✅ User already has ${roomCheck.rows.length} room(s)`);
            console.table(roomCheck.rows);
        } else {
            // Create default room
            const result = await db.query(`
                INSERT INTO user_rooms (user_id, room_type, is_active)
                VALUES ($1, 'exam', TRUE)
                RETURNING *
            `, [userId]);

            console.log('✅ Created default room:');
            console.table(result.rows);
        }

        process.exit();
    } catch (err) {
        console.error('❌ Error:', err.message);
        process.exit(1);
    }
}

createDefaultRoom();
