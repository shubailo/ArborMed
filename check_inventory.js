const db = require('./backend/src/config/db');

async function checkInventory() {
    try {
        const result = await db.query("SELECT COUNT(*) FROM user_items");
        console.log(`Current User Items Count: ${result.rows[0].count}`);

        const sessions = await db.query("SELECT COUNT(*) FROM quiz_sessions");
        console.log(`Current Quiz Sessions Count: ${sessions.rows[0].count}`);

        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkInventory();
