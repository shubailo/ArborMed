const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function getStats() {
    try {
        const res = await pool.query(`
      SELECT t_parent.name_en as subject, COUNT(q.id) as q_count 
      FROM topics t_parent 
      LEFT JOIN topics t_child ON t_child.parent_id = t_parent.id 
      LEFT JOIN questions q ON q.topic_id = t_child.id AND q.active = TRUE 
      WHERE t_parent.parent_id IS NULL 
      GROUP BY t_parent.id, t_parent.name_en
    `);
        console.log('Subject Stats:');
        res.rows.forEach(r => console.log(` - ${r.subject}: ${r.q_count}`));
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

getStats();
