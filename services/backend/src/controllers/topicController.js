const db = require('../config/db');
const { checkTopics, withQuestionWrite } = require('../services/adminQuestionAccess');
const { positiveId } = require('../utils/quizIds');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

exports.getTopics = catchAsync(async (_req, res) => {
    const result = await db.query(`
        WITH RECURSIVE direct AS (
            SELECT q.topic_id, count(*) AS n FROM questions q WHERE q.active = TRUE GROUP BY q.topic_id
        ), ancestors(source, id) AS (
            SELECT topic_id, topic_id FROM direct
            UNION
            SELECT a.source, t.parent_id FROM ancestors a
            JOIN topics t ON t.id = a.id WHERE t.parent_id IS NOT NULL
        ), totals AS (
            SELECT a.id, sum(d.n)::bigint AS n FROM ancestors a JOIN direct d ON d.topic_id = a.source GROUP BY a.id
        )
        SELECT t.*, coalesce(totals.n, 0) AS question_count FROM topics t
        LEFT JOIN totals ON totals.id = t.id ORDER BY t.parent_id NULLS FIRST, t.id
    `);
    res.json(result.rows);
});

function topicId(value) {
    const id = positiveId(value);
    if (id === null) throw new AppError('Invalid topic ID.', 400);
    return id;
}

function topicFields(body) {
    if (!body || typeof body !== 'object' || Array.isArray(body)) throw new AppError('Expected topic fields.', 400);
    const fields = {};
    for (const key of ['name_en', 'name_hu', 'slug', 'description']) {
        if (!Object.hasOwn(body, key)) continue;
        if (body[key] === null && (key === 'description' || key === 'name_hu')) {
            fields[key] = key === 'name_hu' ? '' : null;
            continue;
        }
        const value = body[key];
        if (typeof value !== 'string' || value.includes('\0')) throw new AppError('Invalid ' + key, 400);
        fields[key] = value.trim();
        if (key !== 'description' && [...fields[key]].length > 100) throw new AppError(key + ' exceeds 100 characters.', 400);
        if ((key === 'name_en' || key === 'slug') && !fields[key]) throw new AppError(key + ' is required.', 400);
    }
    if (Object.hasOwn(body, 'parent_id')) fields.parent_id = body.parent_id === null ? null : topicId(body.parent_id);
    if (!Object.keys(fields).length) throw new AppError('Expected topic fields.', 400);
    return fields;
}

function defaultSlug(name, parent) {
    const base = name.normalize('NFKD').replace(/\p{M}/gu, '').toLowerCase()
        .replace(/[^\p{L}\p{N}]+/gu, '-').replace(/^-|-$/g, '');
    if (!base) throw new AppError('This name needs an explicit slug.', 400);
    const prefix = parent == null ? '' : parent + '-';
    return prefix + [...base].slice(0, 100 - prefix.length).join('').replace(/-$/, '');
}

async function topicWrite(userId, ids, action) {
    try {
        return await withQuestionWrite(userId, { topicIds: ids, changeHierarchy: true }, action);
    } catch (err) {
        if (err.code === '23505') throw new AppError('This topic slug is already in use.', 409);
        if (err.code === '23503') throw new AppError('The topic is still referenced by another record.', 409);
        throw err;
    }
}

async function requireParent(client, parent) {
    if (parent != null && !(await client.query('SELECT FROM topics WHERE id = $1', [parent])).rowCount) {
        throw new AppError('Parent topic not found.', 404);
    }
}

exports.createTopic = catchAsync(async (req, res) => {
    const fields = topicFields(req.body);
    const { name_en, name_hu = '', parent_id = null, description } = fields;
    if (!name_en) throw new AppError('name_en is required.', 400);
    const slug = fields.slug ?? defaultSlug(name_en, parent_id);
    const result = await topicWrite(req.user.id, [parent_id], async client => {
        await requireParent(client, parent_id);
        return client.query(
            'INSERT INTO topics (name_en, name_hu, slug, parent_id, description) VALUES ($1,$2,$3,$4,$5) RETURNING *',
            [name_en, name_hu, slug, parent_id, description]);
    });
    res.status(201).json(result.rows[0]);
});

// Progress and Nexus links address a topic by its slug, independently of SQL foreign keys.
async function checkSlugReferences(client, slug) {
    const references = await client.query(`SELECT 1 WHERE
        EXISTS (SELECT FROM user_topic_progress WHERE topic_slug = $1)
        OR EXISTS (SELECT FROM topics WHERE nexus_metadata @>
            jsonb_build_object('nexus_links', jsonb_build_array(jsonb_build_object('topic_slug', $1::text))))`, [slug]);
    if (references.rowCount) throw new AppError('This topic is referenced by study progress or a Nexus link.', 409);
}

exports.updateTopic = catchAsync(async (req, res) => {
    const id = topicId(req.params.id);
    const fields = topicFields(req.body);
    const result = await topicWrite(req.user.id, [id], async (client, scope) => {
        const { rows: [current] } = await client.query('SELECT * FROM topics WHERE id = $1 FOR UPDATE', [id]);
        if (!current) throw new AppError('Topic not found.', 404);
        const next = { ...current, ...fields };
        if (next.parent_id !== current.parent_id) {
            checkTopics(scope, [next.parent_id]);
            await requireParent(client, next.parent_id);
            const cycle = await client.query(
                `WITH RECURSIVE subtree(id) AS (SELECT id FROM topics WHERE id = $1
                 UNION SELECT t.id FROM topics t JOIN subtree s ON t.parent_id = s.id)
                 SELECT FROM subtree WHERE id = $2`, [id, next.parent_id]);
            if (cycle.rowCount) throw new AppError('A topic cannot be moved under itself or a descendant.', 400);
        }
        if (current.slug !== next.slug) await checkSlugReferences(client, current.slug);
        return client.query(
            'UPDATE topics SET name_en=$1, name_hu=$2, slug=$3, parent_id=$4, description=$5 WHERE id=$6 RETURNING *',
            [next.name_en, next.name_hu, next.slug, next.parent_id, next.description, id]);
    });
    res.json(result.rows[0]);
});

exports.deleteTopic = catchAsync(async (req, res) => {
    const id = topicId(req.params.id);
    const result = await topicWrite(req.user.id, [id], async client => {
        const { rows: [topic] } = await client.query('SELECT slug FROM topics WHERE id=$1 FOR UPDATE', [id]);
        if (!topic) throw new AppError('Topic not found.', 404);
        const linked = await client.query(`SELECT 1 WHERE EXISTS (SELECT FROM topics WHERE parent_id=$1)
            OR EXISTS (SELECT FROM users WHERE assigned_subject_id=$1)`, [id]);
        if (linked.rowCount) throw new AppError('Reassign child topics and assigned editors before deletion.', 409);
        await checkSlugReferences(client, topic.slug);
        const { rows: [set] } = await client.query(`WITH locked AS (
            SELECT id FROM questions WHERE topic_id=$1 ORDER BY id FOR UPDATE
        ) SELECT count(*)::integer AS count, md5($1::integer::text || ':' || string_agg(id::text, ',' ORDER BY id)) AS version
          FROM locked`, [id]);
        if (set.count) {
            const history = await client.query(`WITH section AS (SELECT id FROM questions WHERE topic_id=$1)
                SELECT 1 WHERE EXISTS (SELECT FROM responses JOIN section ON section.id=responses.question_id)
                OR EXISTS (SELECT FROM user_question_progress p JOIN section ON section.id=p.question_id)
                OR EXISTS (
                    SELECT FROM questions ref
                    CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(ref.metadata->'prerequisite_ids')='array'
                        THEN ref.metadata->'prerequisite_ids' ELSE '[]'::jsonb END) AS link(value)
                    JOIN section ON section.id::text = ltrim(CASE jsonb_typeof(link.value)
                        WHEN 'number' THEN trim_scale(link.value::numeric)::text
                        WHEN 'string' THEN regexp_replace(link.value #>> '{}', '^[[:space:]]+|[[:space:]]+$', '', 'g')
                    END, '0')
                    WHERE ref.topic_id IS DISTINCT FROM $1 AND ref.metadata ? 'prerequisite_ids'
                )`, [id]);
            if (history.rowCount) throw new AppError('A question has student history or is used as a prerequisite.', 409);
            if (req.query.force !== 'true' || req.query.confirmation !== set.version) {
                return { code: 'topic_questions_confirmation', count: set.count, confirmation: set.version,
                    message: 'Confirm deletion of the questions in this section.' };
            }
            await client.query('DELETE FROM questions WHERE topic_id=$1', [id]);
        }
        await client.query('DELETE FROM topics WHERE id=$1', [id]);
        return null;
    });
    if (result) return res.status(409).json(result);
    res.json({ message: 'Topic deleted' });
});
