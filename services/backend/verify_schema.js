const { Client } = require('pg');
const client = new Client({ connectionString: 'postgresql://postgres.qjyxnbernwfodsnxirle:Eklics62343.@aws-1-eu-west-1.pooler.supabase.com:6543/postgres' });
async function test() {
  try {
    await client.connect();
    
    // Check topics.description
    const topicsRes = await client.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'topics' AND column_name = 'description'");
    console.log('TOPICS_DESC_FOUND: ' + (topicsRes.rows.length > 0));
    
    // Check questions.active
    const questionsRes = await client.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'questions' AND column_name = 'active'");
    console.log('QUESTIONS_ACTIVE_FOUND: ' + (questionsRes.rows.length > 0));
    
    // Check user_activity table
    const activityRes = await client.query("SELECT table_name FROM information_schema.tables WHERE table_name = 'user_activity'");
    console.log('USER_ACTIVITY_TABLE_FOUND: ' + (activityRes.rows.length > 0));
    
  } catch (e) {
    console.error('Error during verification:', e.message);
  } finally {
    await client.end();
  }
}
test();
