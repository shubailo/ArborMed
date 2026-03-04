function buildBulkInsert(questions, userId) {
    if (questions.length === 0) return null;
    let query = `INSERT INTO questions (question_text_en, question_text_hu, topic_id, bloom_level, difficulty, type, question_type, correct_answer, options, explanation_en, explanation_hu, created_by) VALUES `;
    const params = [];
    const values = [];
    let offset = 1;
    for (const q of questions) {
        values.push(`($${offset}, $${offset+1}, $${offset+2}, $${offset+3}, $${offset+3}, $${offset+4}, $${offset+4}, $${offset+5}, $${offset+6}, $${offset+7}, $${offset+8}, $${offset+9})`);

        const optListEn = q.optEn ? q.optEn.toString().split(';') : [];
        const optListHu = q.optHu ? q.optHu.toString().split(';') : [];
        const optionsJson = JSON.stringify({ en: optListEn, hu: optListHu });

        params.push(
            q.q_en || '',
            q.q_hu || '',
            q.topic_id,
            parseInt(q.bloom) || 1,
            q.type || 'single_choice',
            q.correctAns || '',
            optionsJson,
            q.expEn || '',
            q.expHu || '',
            userId
        );
        offset += 10;
    }
    query += values.join(', ');
    return { sql: query, params };
}

function buildBulkUpdate(questions) {
    if (questions.length === 0) return null;

    const ids = [], qEn = [], qHu = [], topicId = [], bloom = [],
          type = [], correctAns = [], options = [], expEn = [], expHu = [];

    for (const q of questions) {
        const optListEn = q.optEn ? q.optEn.toString().split(';') : [];
        const optListHu = q.optHu ? q.optHu.toString().split(';') : [];
        const optionsJson = JSON.stringify({ en: optListEn, hu: optListHu });

        ids.push(q.db_id);
        qEn.push(q.q_en || null);
        qHu.push(q.q_hu || null);
        topicId.push(q.topic_id);
        bloom.push(parseInt(q.bloom) || 1);
        type.push(q.type || 'single_choice');
        correctAns.push(q.correctAns || null);
        options.push(optionsJson);
        expEn.push(q.expEn || '');
        expHu.push(q.expHu || '');
    }

    const query = `
        UPDATE questions
        SET
            question_text_en = c.q_en,
            question_text_hu = c.q_hu,
            topic_id = c.topic_id,
            difficulty = c.bloom,
            bloom_level = c.bloom,
            type = c.type,
            question_type = c.type,
            correct_answer = c.correct_ans,
            options = c.options::jsonb,
            explanation_en = c.exp_en,
            explanation_hu = c.exp_hu
        FROM (
            SELECT
                unnest($1::int[]) as id,
                unnest($2::text[]) as q_en,
                unnest($3::text[]) as q_hu,
                unnest($4::int[]) as topic_id,
                unnest($5::int[]) as bloom,
                unnest($6::text[]) as type,
                unnest($7::text[]) as correct_ans,
                unnest($8::text[]) as options,
                unnest($9::text[]) as exp_en,
                unnest($10::text[]) as exp_hu
        ) as c
        WHERE questions.id = c.id
    `;

    return {
        sql: query,
        params: [ids, qEn, qHu, topicId, bloom, type, correctAns, options, expEn, expHu]
    };
}

const questions = [
    { db_id: 1, topic_id: 2, q_en: "Update Q1" },
    { db_id: 2, topic_id: 3, q_en: "Update Q2", bloom: 3 }
];
console.log(buildBulkUpdate(questions));

const insertQuestions = [
    { topic_id: 2, q_en: "Insert Q1" },
    { topic_id: 3, q_en: "Insert Q2", bloom: 3 }
];
console.log(buildBulkInsert(insertQuestions, 99));
