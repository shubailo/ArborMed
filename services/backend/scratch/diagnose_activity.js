const db = require('../src/config/db');

async function diagnose() {
  try {
    const userResult = await db.query("SELECT id, email FROM users WHERE email = 'shubailobeid@gmail.com'");
    if (userResult.rows.length === 0) {
      console.log("User not found");
      return;
    }
    const userId = userResult.rows[0].id;
    console.log(`User ID: ${userId}`);

    const respCount = await db.query("SELECT COUNT(*) FROM responses r JOIN quiz_sessions qs ON r.session_id = qs.id WHERE qs.user_id = $1", [userId]);
    console.log(`Total responses for user: ${respCount.rows[0].count}`);

    const sample = await db.query(`
      SELECT r.id, r.created_at, r.session_id, q.question_text_en 
      FROM responses r 
      JOIN quiz_sessions qs ON r.session_id = qs.id 
      JOIN questions q ON q.id = r.question_id
      WHERE qs.user_id = $1 
      LIMIT 10
    `, [userId]);
    console.table(sample.rows);

  } catch (err) {
    console.error(err);
  } finally {
    process.exit();
  }
}

diagnose();
