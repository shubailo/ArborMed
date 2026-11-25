const { readFileSync } = require('node:fs');
const path = require('node:path');
const { Client } = require('pg');
const questions = require('../../src/data/questions/cardovascular_questions.json');

const postgres = process.env.TEST_DATABASE_URL ? describe : describe.skip;
postgres('reviewed question data migration', () => {
    const repaired = questions.find(q => q.id === 'tk2_4_6');
    const withheld = questions.find(q => q.id === 'tk2_5_24');
    const sql = readFileSync(path.join(__dirname, '../../migrations/066_review_question_keys.sql'), 'utf8');

    test.each(['text','jsonb'])('repairs exact matches on a %s key column and preserves local edits', async type => {
        const pg = new Client({ connectionString: process.env.TEST_DATABASE_URL });
        await pg.connect();
        try {
            await pg.query(`CREATE TEMP TABLE questions(id int, type text, question_type text,
                question_text_en text, question_text_hu text, options jsonb, content jsonb,
                correct_answer ${type}, active boolean)`);
            const oldKey = repaired.correct_answer.flatMap(label => label.split(', '));
            for (const [id, q, key] of [[1, repaired, oldKey], [2, withheld, withheld.correct_answer],
                [3, {...withheld, question_text_hu: 'Edited by the local instructor'}, withheld.correct_answer]]) {
                const stored = type === 'text' && typeof key === 'string' ? key : JSON.stringify(key);
                await pg.query('INSERT INTO questions VALUES ($1,$2,$2,$3,$4,$5,$6,$7,true)',
                    [id,q.question_type,q.question_text_en,q.question_text_hu,JSON.stringify(q.options),'{}',stored]);
            }
            await pg.query(sql);
            const {rows} = await pg.query('SELECT active, correct_answer FROM questions ORDER BY id');
            expect(rows.map(r => r.active)).toEqual([true,false,true]);
            expect(type === 'text' ? JSON.parse(rows[0].correct_answer) : rows[0].correct_answer).toEqual(repaired.correct_answer);
        } finally { await pg.end(); }
    });
});
