const db = require('../config/db');

async function fixPaths() {
    await db.query("UPDATE items SET asset_path = 'assets/images/furniture/desk.png' WHERE name = 'Modern Glass Desk'");
    await db.query("UPDATE items SET asset_path = 'assets/images/furniture/gurney.png' WHERE name = 'Blue Gurney'");
    console.log('Fixed core asset paths.');
    process.exit();
}
fixPaths();
