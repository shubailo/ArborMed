const db = require('./src/config/db');

async function checkPermissions() {
    try {
        console.log('--- 🛡️ Permission Diagnostic ---');

        const ownerResult = await db.query(`
            SELECT tablename, tableowner 
            FROM pg_tables 
            WHERE tablename = 'users';
        `);
        console.log('Table Owner:', ownerResult.rows[0]);

        const currentUser = await db.query('SELECT CURRENT_USER, SESSION_USER;');
        console.log('Current User:', currentUser.rows[0]);

        const userPrivs = await db.query(`
            SELECT grantee, privilege_type 
            FROM information_schema.role_table_grants 
            WHERE table_name = 'users' AND grantee = CURRENT_USER;
        `);
        console.log('User Privileges:', userPrivs.rows);

    } catch (error) {
        console.error('❌ Diagnostic failed:', error.message);
    } finally {
        process.exit();
    }
}

checkPermissions();
