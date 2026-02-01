const db = require('./src/config/db');

async function inspectTable() {
    try {
        const res = await db.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'ecg_cases';
    `);
        console.log(res.rows);
    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

inspectTable();
