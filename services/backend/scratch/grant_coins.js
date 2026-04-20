const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function grantCoins() {
  const email = 'shubailobeid@gmail.com';
  const amount = 1000;
  
  console.log(`Granting ${amount} coins to ${email}...`);
  
  try {
    const res = await pool.query(
      'UPDATE users SET coins = coins + $1 WHERE email = $2 RETURNING id, username, coins',
      [amount, email]
    );
    
    if (res.rowCount > 0) {
      console.log('SUCCESS: Clinical funds granted.');
      console.table(res.rows);
    } else {
      console.error('FAILURE: User not found.');
      
      // List all users to help debug
      const allUsers = await pool.query('SELECT id, email, username FROM users LIMIT 10');
      console.log('Available users:');
      console.table(allUsers.rows);
    }
  } catch (err) {
    console.error('DATABASE ERROR:', err.message);
  } finally {
    await pool.end();
  }
}

grantCoins();
