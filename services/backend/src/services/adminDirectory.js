const db = require('../config/db');
const AppError = require('../utils/AppError');

// The Flutter directory uses "cases" for the case-studies subject.
const subjects = new Map([
    ['pathophysiology', 'pathophysiology'], ['pathology', 'pathology'],
    ['microbiology', 'microbiology'], ['pharmacology', 'pharmacology'],
    ['ecg', 'ecg'], ['cases', 'case-studies'],
]);

const subjectTopics = `subject_topics(id, root_id) AS (
    SELECT id, id FROM topics WHERE parent_id IS NULL
    UNION ALL
    SELECT t.id, parent.root_id FROM topics t JOIN subject_topics parent ON parent.id = t.parent_id
)`;

function positivePage(value) {
    if (!/^\d+$/.test(String(value)) || !Number.isSafeInteger(Number(value)) || Number(value) < 1) {
        throw new AppError('Invalid pagination parameters', 400);
    }
    return Number(value);
}

function studentQuery(where, slice, sort, direction) {
    const byActivity = sort === 'activity';
    const activityOrder = `u.last_activity_at ${direction} NULLS LAST, u.created_at DESC, u.id`;
    // For the common activity view, aggregate answers only for the accounts on this page.
    // A subject sort needs scores for all matching students before applying the page limit.
    const joins = [];
    const fields = [];
    for (const [key, slug] of subjects) {
        joins.push(`LEFT JOIN scores ${key} ON ${key}.user_id = u.id AND ${key}.slug = '${slug}'`);
        for (const metric of ['avg', 'total', 'correct', 'time']) {
            fields.push(`coalesce(${key}.${metric}, 0) AS ${key}_${metric}`);
        }
    }
    return `WITH RECURSIVE ${subjectTopics}, candidates AS (
        SELECT u.id, u.email, u.created_at, u.last_activity_at FROM users u ${where}
        ${byActivity ? 'ORDER BY ' + activityOrder + ' ' + slice : ''}
    ), attempts AS (
        SELECT r.user_id, r.question_id, r.is_correct, r.response_time_ms
        FROM candidates c JOIN responses r ON r.user_id = c.id
        UNION ALL
        SELECT s.user_id, r.question_id, r.is_correct, r.response_time_ms
        FROM candidates c JOIN quiz_sessions s ON s.user_id = c.id
        JOIN responses r ON r.session_id = s.id WHERE r.user_id IS NULL
    ), scores AS (
        SELECT a.user_id, subject.slug, count(*)::int AS total,
               count(*) FILTER (WHERE a.is_correct)::int AS correct,
               round(avg(CASE WHEN a.is_correct THEN 100 ELSE 0 END))::int AS avg,
               round(avg(a.response_time_ms))::int AS time
        FROM attempts a JOIN questions q ON q.id = a.question_id
        JOIN subject_topics t ON t.id = q.topic_id JOIN topics subject ON subject.id = t.root_id
        GROUP BY a.user_id, subject.slug
    )
    SELECT u.id, u.email, u.created_at, u.last_activity_at AS last_activity, ${fields.join(', ')}
    FROM candidates u ${joins.join('\n')}
    ORDER BY ${byActivity ? activityOrder : sort + '.avg ' + direction + ' NULLS LAST, u.id'}
    ${byActivity ? '' : slice}`;
}

function adminQuery(where, slice, direction) {
    return `SELECT u.id, u.email, u.role, u.created_at, u.last_activity_at AS last_activity,
        u.assigned_subject_id, t.name_en AS assigned_subject_name, t.name_hu AS assigned_subject_name_hu,
        (SELECT count(*)::int FROM questions q WHERE q.created_by = u.id) AS questions_uploaded
        FROM users u LEFT JOIN topics t ON t.id = u.assigned_subject_id ${where}
        ORDER BY u.last_activity_at ${direction} NULLS LAST, u.created_at DESC, u.id ${slice}`;
}

async function listDirectory(query, role) {
    const page = positivePage(query.page ?? 1);
    const limit = Math.min(positivePage(query.limit ?? 50), 1000);
    const offset = (page - 1) * limit;
    if (!Number.isSafeInteger(offset)) throw new AppError('Invalid pagination parameters', 400);
    const { sort = 'activity', direction = 'desc', search = '' } = query;
    if (!(sort === 'activity' || (role === 'student' && subjects.has(sort))) ||
        !['asc', 'desc'].includes(direction) || typeof search !== 'string') {
        throw new AppError('Invalid directory filters', 400);
    }
    const params = [role];
    let where = 'WHERE u.role = $1';
    if (role === 'student') {
        where += " AND u.email NOT IN ('test_reset@example.com', 'hemmy@arbormed.ai', 'endre@medbuddy.ai')";
    }
    const term = search.trim();
    if (term) {
        params.push('%' + term.replace(/[\\%_]/g, '\\$&') + '%');
        where += ' AND (u.email ILIKE $2';
        const id = /^#?(\d+)$/.exec(term);
        if (id && Number(id[1]) > 0 && Number(id[1]) <= 2147483647) {
            params.push(Number(id[1]));
            where += ' OR u.id = $3';
        }
        where += ')';
    }
    const slice = `LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    const dataQuery = role === 'student' ? studentQuery(where, slice, sort, direction) : adminQuery(where, slice, direction);
    const [count, data] = await Promise.all([
        db.query(`SELECT count(*) FROM users u ${where}`, params),
        db.query(dataQuery, [...params, limit, offset]),
    ]);
    return { users: data.rows, total: Number(count.rows[0].count), page, limit };
}

async function userHistory(id, limit) {
    const { rows } = await db.query(`WITH RECURSIVE ${subjectTopics}
        SELECT r.id, r.created_at, r.is_correct, r.response_time_ms, q.question_text_en, q.bloom_level,
               section.name_en AS section_name, subject.name_en AS subject_name, subject.slug AS subject_slug
        FROM responses r LEFT JOIN quiz_sessions s ON r.session_id = s.id
        JOIN questions q ON q.id = r.question_id JOIN topics section ON section.id = q.topic_id
        LEFT JOIN subject_topics t ON t.id = section.id LEFT JOIN topics subject ON subject.id = t.root_id
        WHERE coalesce(r.user_id, s.user_id) = $1
        ORDER BY r.created_at DESC, r.id DESC LIMIT $2`, [id, limit]);
    return rows;
}

module.exports = { listDirectory, userHistory };
