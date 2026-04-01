const db = require('../services/backend/src/config/db');

async function checkUsers() {
  try {
    const result = await db.query('SELECT id, email, role, created_at FROM users ORDER BY id ASC');
    console.log(JSON.stringify(result.rows, null, 2));
    process.exit(0);
  } catch (err) {
    console.error('Error fetching users:', err);
    process.exit(1);
  }
}

checkUsers();
