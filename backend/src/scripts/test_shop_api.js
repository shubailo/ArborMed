const axios = require('axios');

async function testApi() {
    try {
        // We'll just run a query directly since we have db access
        const db = require('../config/db');
        const res = await db.query("SELECT * FROM items WHERE slot_type = 'monitor'");
        console.log('Monitor Items:', res.rows);

        const res2 = await db.query("SELECT * FROM items WHERE slot_type = 'wall_ac'");
        console.log('AC Items:', res2.rows);

        process.exit();
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}
testApi();
