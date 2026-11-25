const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const { Client } = require('pg');
const { migrate } = require('../../src/scripts/migrate');

const postgres = process.env.TEST_DATABASE_URL ? describe : describe.skip;
postgres('forward migrations on PostgreSQL', () => {
    let pg, dir;
    const first = '060_first.sql';
    const second = '061_second.sql';
    const apply = () => migrate(pg, { dir });
    const baseline = () => migrate(pg, { dir, baselineOnly: true });
    const write = (file, sql) => fs.writeFile(path.join(dir, file), sql);
    const installed = async () => (await pg.query(
        'SELECT filename FROM arbormed_schema_migrations ORDER BY filename'
    )).rows.map(row => row.filename);

    beforeAll(async () => {
        pg = new Client({ connectionString: process.env.TEST_DATABASE_URL });
        await pg.connect();
        await pg.query(`
            CREATE TEMP TABLE users(id int, coins int, password_hash text, is_email_verified boolean);
            SET search_path TO pg_temp;
            CREATE TEMP TABLE refresh_tokens(revoked boolean);
            CREATE TEMP TABLE questions(metadata jsonb);
            CREATE TEMP TABLE responses(user_id int);
            CREATE TEMP TABLE user_topic_progress(user_id int);
            CREATE TEMP TABLE quiz_sessions(user_id int);
        `);
    });
    afterAll(async () => { await pg.end(); });
    beforeEach(async () => {
        dir = await fs.mkdtemp(path.join(os.tmpdir(), 'arbormed-migrations-'));
    });
    afterEach(async () => {
        await pg.query('DROP TABLE IF EXISTS pg_temp.arbormed_schema_migrations, pg_temp.first_applied, pg_temp.second_applied, pg_temp.ecg_cases');
        for (const file of await fs.readdir(dir)) await fs.unlink(path.join(dir, file));
        await fs.rmdir(dir);
    });

    test('requires an explicit baseline, runs each forward file once, normalizes line endings and detects edits', async () => {
        const sql = 'CREATE TABLE first_applied (value int);\nINSERT INTO first_applied VALUES (3);\n';
        await write(first, sql);
        await expect(apply()).rejects.toThrow(/baseline/i);
        expect(await installed()).toEqual([]);
        await baseline();
        await apply();
        await write(first, sql.replace(/\n/g, '\r\n'));
        await apply();
        expect((await pg.query('SELECT value FROM first_applied')).rows).toEqual([{ value: 3 }]);
        await write(first, sql.replace('VALUES (3)', 'VALUES (4)'));
        await expect(apply()).rejects.toThrow(/060_first/);
    });

    test('rolls back the failed file together with its tracking record and can safely retry', async () => {
        await baseline();
        await write(first, 'CREATE TABLE first_applied(value int)');
        await write(second, 'CREATE TABLE second_applied(value int); INSERT INTO missing_fixture_table VALUES (1)');
        await expect(apply()).rejects.toThrow(/061_second/);
        expect(await installed()).toContain(first);
        expect(await installed()).not.toContain(second);
        expect((await pg.query("SELECT to_regclass('pg_temp.second_applied') AS t")).rows[0].t).toBeNull();
        await write(second, 'CREATE TABLE second_applied(value int)');
        await apply();
        expect(await installed()).toContain(second);
    });

    test('rejects duplicate versions before installing either file', async () => {
        await baseline();
        await write(first, 'CREATE TABLE first_applied(value int)');
        await write('060_second.sql', 'CREATE TABLE second_applied(value int)');
        await expect(apply()).rejects.toThrow(/duplicate/i);
        expect(await installed()).not.toContain(first);
    });

    test('detects a renamed applied file before executing replacement SQL', async () => {
        await baseline();
        await write(first, 'CREATE TABLE first_applied(value int)');
        await apply();
        await fs.unlink(path.join(dir, first));
        await write('060_renamed.sql', 'CREATE TABLE second_applied(value int)');
        await expect(apply()).rejects.toThrow();
        expect((await pg.query("SELECT to_regclass('pg_temp.second_applied') AS t")).rows[0].t).toBeNull();
    });
    test('enforces the applied version sequence before running more SQL', async () => {
        await baseline();
        await write(second, 'CREATE TABLE second_applied(value int)');
        await apply();
        await write(first, 'CREATE TABLE first_applied(value int)');
        await expect(apply()).rejects.toThrow(/060_first/);
        expect((await pg.query("SELECT to_regclass('pg_temp.first_applied') AS t")).rows[0].t).toBeNull();
    });

    test('private quiz grading data are accessible only to the backend roles', async () => {
        await pg.query(`GRANT SELECT ON questions TO PUBLIC;
            ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
            CREATE POLICY "Public Read Access" ON questions FOR SELECT TO public USING (true)`);
        const sql = await fs.readFile(path.join(__dirname, '../../migrations/064_private_questions.sql'), 'utf8');
        await pg.query(sql);
        const { rows } = await pg.query(`SELECT relrowsecurity, EXISTS (
            SELECT FROM aclexplode(relacl) a WHERE grantee = 0) AS public_grants,
            EXISTS (SELECT FROM pg_policy WHERE polrelid = c.oid AND 0 = ANY(polroles)) AS public_policy
            FROM pg_class c WHERE oid = 'pg_temp.questions'::regclass`);
        expect(rows).toEqual([{ relrowsecurity: true, public_grants: false, public_policy: false }]);
    });

    test('removes legacy public ECG read access and protects migration records', async () => {
        await baseline();
        await pg.query(`
            CREATE TEMP TABLE ecg_cases(id int);
            GRANT SELECT ON ecg_cases TO PUBLIC;
            ALTER TABLE ecg_cases ENABLE ROW LEVEL SECURITY;
            CREATE POLICY "Public Read Access" ON ecg_cases FOR SELECT TO public USING (true);
        `);
        await pg.query(await fs.readFile(path.join(__dirname, '../../migrations/063_private_ecg_cases.sql'), 'utf8'));
        const protectedTables = await pg.query(`
            SELECT relname, relrowsecurity AS protected,
                EXISTS (SELECT FROM aclexplode(relacl) AS a WHERE grantee = 0) AS public_access
            FROM pg_catalog.pg_class WHERE relnamespace = pg_my_temp_schema()
                AND relname IN ('arbormed_schema_migrations','ecg_cases') ORDER BY relname
        `);
        expect(protectedTables.rows).toEqual([
            { relname: 'arbormed_schema_migrations', protected: true, public_access: false },
            { relname: 'ecg_cases', protected: true, public_access: false },
        ]);
        const publicPolicy = await pg.query(`SELECT FROM pg_catalog.pg_policy
            WHERE polrelid = 'pg_temp.ecg_cases'::regclass AND 0 = ANY(polroles)`);
        expect(publicPolicy.rowCount).toBe(0);
    });
});
