const ExcelJS = require('exceljs');
const db = require('../config/db');
const AppError = require('../utils/AppError');
const { positiveId } = require('../utils/quizIds');
const JSZip = require('jszip');
const { Writable } = require('node:stream');
const { pipeline } = require('node:stream/promises');
const { parseString } = require('fast-csv');

const maxRows = 5000;
const key = value =>
    String(value ?? '')
        .trim()
        .normalize('NFC')
        .toLowerCase();

function indexName(index, value, id) {
    const name = key(value);
    if (name) index.set(name, index.has(name) && index.get(name) !== id ? null : id);
}

// The workbook and the importer use the same scoped names and catalog snapshot.
async function topicCatalog() {
    const { rows } = await db.query(
        'SELECT id, parent_id, name_en, name_hu FROM topics ORDER BY name_en, id'
    );
    const children = new Map();
    for (const t of rows) {
        if (!children.has(t.parent_id)) children.set(t.parent_id, []);
        children.get(t.parent_id).push(t);
    }
    const subjects = children.get(null) || [];
    const rootNames = new Map(),
        all = new Map(),
        sections = new Map(),
        owners = new Map();
    for (const root of subjects) {
        indexName(rootNames, root.name_en, root.id);
        indexName(rootNames, root.name_hu, root.id);
    }
    for (const root of subjects) {
        root.label =
            !positiveId(root.name_en) && rootNames.get(key(root.name_en)) === root.id
                ? root.name_en
                : `${root.name_en} [#${root.id}]`;
        indexName(rootNames, root.label, root.id);
        const nodes = [],
            names = new Map(),
            paths = new Map();
        const stack = [[root, '']];
        while (stack.length) {
            const [t, parentPath] = stack.pop();
            if (owners.has(t.id)) continue;
            owners.set(t.id, root.id);
            const path = parentPath ? parentPath + ' › ' + t.name_en : t.name_en;
            nodes.push({ t, path });
            indexName(paths, path, t.id);
            for (const name of [t.name_en, t.name_hu, path]) {
                indexName(names, name, t.id);
                indexName(all, name, t.id);
            }
            for (const child of (children.get(t.id) || []).slice().reverse())
                stack.push([child, t === root ? '' : path]);
        }
        const labels = [];
        for (const { t, path } of nodes) {
            const label =
                !positiveId(path) && paths.get(key(path)) === t.id && names.get(key(path)) === t.id
                    ? path
                    : `${path} [#${t.id}]`;
            indexName(names, label, t.id);
            indexName(all, label, t.id);
            if (t !== root || nodes.length === 1) labels.push(label);
        }
        sections.set(root.id, { labels, names });
    }
    return {
        subjects,
        sections,
        resolve(subject, topic) {
            function resolveName(value, names, validId) {
                const named = names.get(key(value));
                const id = positiveId(value);
                if (id && validId(id)) return named === undefined || named === id ? id : null;
                return named;
            }
            const root = resolveName(subject, rootNames, id => sections.has(id));
            if (key(subject) && root == null) return null;
            if (!key(topic)) return root;
            const names = root ? sections.get(root).names : all;
            return resolveName(topic, names, id => owners.has(id) && (!root || owners.get(id) === root));
        }
    };
}

async function checkWorkbook(buffer, maxBytes = 32 * 1024 * 1024) {
    const zip = await JSZip.loadAsync(buffer);
    const entries = Object.values(zip.files);
    if (!zip.file('[Content_Types].xml') || !zip.file('xl/workbook.xml'))
        throw new AppError('Expected an XLSX workbook.', 400);
    if (entries.length > 2000) throw new AppError('Too many workbook parts.', 413);
    let bytes = 0;
    for (const entry of entries) {
        if (entry.dir) continue;
        await pipeline(
            entry.nodeStream(),
            new Writable({
                write(chunk, encoding, next) {
                    bytes += chunk.length;
                    next(bytes > maxBytes ? new AppError('Expanded workbook exceeds 32 MiB.', 413) : null);
                }
            })
        );
    }
}

function cellText(value) {
    if (value == null) return '';
    if (typeof value !== 'object') return String(value);
    if (Array.isArray(value.richText)) return value.richText.map(run => run.text).join('');
    if (Object.hasOwn(value, 'result')) return cellText(value.result);
    if (typeof value.text === 'string') return value.text;
    throw new Error('A cell requires a literal value or a cached result.');
}

const registry = require('./questionTypes/registry');

/**
 * Service to handle question template generation and parsing for Excel files.
 */
class AdminExcelService {
    /**
     * Generates a user-friendly Excel template for bulk question upload.
     * Includes dropdowns for topics, bloom levels, and question types.
     */
    async generateTemplate() {
        const workbook = new ExcelJS.Workbook();

        // 1. Data Reference Sheet (Hidden eventually)
        const refSheet = workbook.addWorksheet('Reference');

        // Fetch Subjects and Topics
        const { subjects, sections } = await topicCatalog();
        const typeValidation = {
            type: 'list',
            formulae: [
                '"' +
                    registry
                        .getAllTypes()
                        .map(t => t.id)
                        .join(',') +
                    '"'
            ]
        };
        const topicValidation = subjectCell => ({
            type: 'list',
            allowBlank: true,
            formulae: [`INDIRECT("SubjectSections_"&MATCH(${subjectCell},SubjectsList,0))`]
        });

        // Populate Reference Sheet for Cascading Dropdowns
        // Col A: Subjects
        subjects.forEach((s, i) => {
            refSheet.getCell(`A${i + 1}`).value = s.label;

            // For each subject, create a column of its topics for Named Ranges
            const subjectTopics = sections.get(s.id).labels;
            const colLetter = refSheet.getColumn(i + 2).letter;

            subjectTopics.forEach((tName, tIdx) => {
                refSheet.getCell(`${colLetter}${tIdx + 1}`).value = tName;
            });

            const range = `Reference!$${colLetter}$1:$${colLetter}$${Math.max(subjectTopics.length, 1)}`;
            workbook.definedNames.add(range, `SubjectSections_${i + 1}`);
        });

        workbook.definedNames.add(`Reference!$A$1:$A$${Math.max(subjects.length, 1)}`, 'SubjectsList');

        // 2. Entry Form Sheet (Visual/Adaptive)
        const formSheet = workbook.addWorksheet('Quick Entry Form');

        // Styling helpers
        const headerStyle = {
            font: { bold: true, color: { argb: 'FFFFFFFF' } },
            fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF4A90E2' } },
            alignment: { horizontal: 'center' }
        };
        const labelStyle = {
            font: { bold: true },
            fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF5F7F9' } }
        };
        const borderStyle = {
            top: { style: 'thin' },
            left: { style: 'thin' },
            bottom: { style: 'thin' },
            right: { style: 'thin' }
        };

        formSheet.getColumn('A').width = 20;
        formSheet.getColumn('B').width = 40;
        formSheet.getColumn('C').width = 40;

        for (let i = 0; i < 20; i++) {
            // Generate 20 entry blocks
            const startRow = i * 15 + 1;

            // Block Header
            const hRow = formSheet.getRow(startRow);
            hRow.values = [`QUESTION #${i + 1}`, 'ENGLISH CONTENT', 'HUNGARIAN CONTENT'];
            hRow.eachCell(cell => {
                cell.style = headerStyle;
                cell.border = borderStyle;
            });
            formSheet.mergeCells(startRow, 1, startRow + 1, 1);

            // Fields
            const fields = [
                {
                    label: 'Subject',
                    key: 'subject',
                    validation: { type: 'list', formulae: ['SubjectsList'] }
                },
                { label: 'Topic (Section)', key: 'topic' }, // Will handle dynamic validation later
                { label: 'Bloom Level', validation: { type: 'list', formulae: ['"1,2,3,4"'] } },
                { label: 'Type', validation: typeValidation },
                { label: 'Question Text', height: 2 },
                { label: 'Correct Answer' },
                { label: 'Options (; sep)', height: 2 },
                { label: 'Explanation', height: 2 },
                { label: 'DB ID (Edit only)' }
            ];

            let currentRow = startRow + 2;
            fields.forEach(f => {
                const labelCell = formSheet.getCell(currentRow, 1);
                labelCell.value = f.label;
                labelCell.style = labelStyle;
                labelCell.border = borderStyle;

                if (f.height > 1) {
                    formSheet.mergeCells(currentRow, 1, currentRow + f.height - 1, 1);
                    formSheet.mergeCells(currentRow, 2, currentRow + f.height - 1, 2);
                    formSheet.mergeCells(currentRow, 3, currentRow + f.height - 1, 3);
                }

                // Apply dynamic validation for Topic
                if (f.key === 'topic') {
                    // Excel magic: INDIRECT depends on the cell above (Subject)
                    const subjectCellAddr = formSheet.getCell(currentRow - 1, 2).address;
                    formSheet.getCell(currentRow, 2).dataValidation = topicValidation(subjectCellAddr);
                    const alternateSubject = formSheet.getCell(currentRow - 1, 3).address;
                    const effectiveSubject = `IF(${subjectCellAddr}="",${alternateSubject},${subjectCellAddr})`;
                    formSheet.getCell(currentRow, 3).dataValidation = topicValidation(effectiveSubject);
                } else if (f.validation) {
                    formSheet.getCell(currentRow, 2).dataValidation = f.validation;
                    formSheet.getCell(currentRow, 3).dataValidation = f.validation;
                }

                formSheet.getCell(currentRow, 2).border = borderStyle;
                formSheet.getCell(currentRow, 3).border = borderStyle;

                currentRow += f.height || 1;
            });

            // Spacing
            formSheet.getRow(currentRow).height = 20;
        }

        // 3. Flat Table Sheet (For bulk power users)
        const dataSheet = workbook.addWorksheet('Questions List');
        const headers = [
            'db_id',
            'link_id',
            'language',
            'subject',
            'topic',
            'question_text',
            'bloom_level',
            'type',
            'correct_answer',
            'options',
            'explanation'
        ];
        dataSheet.addRow(headers);
        dataSheet.getRow(1).font = { bold: true };
        dataSheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE0E0E0' } };

        for (let i = 2; i <= 500; i++) {
            dataSheet.getCell(`C${i}`).dataValidation = { type: 'list', formulae: ['"en,hu"'] };
            dataSheet.getCell(`D${i}`).dataValidation = { type: 'list', formulae: ['SubjectsList'] };
            dataSheet.getCell(`E${i}`).dataValidation = topicValidation(`D${i}`);
            dataSheet.getCell(`G${i}`).dataValidation = { type: 'list', formulae: ['"1,2,3,4"'] };
            dataSheet.getCell(`H${i}`).dataValidation = typeValidation;
        }

        dataSheet.columns.forEach(col => {
            col.width = 20;
        });

        refSheet.state = 'hidden';
        workbook.views = [{ activeTab: 1, firstSheet: 1 }];
        return workbook;
    }

    async parseFile(buffer, mimeType, filename = '') {
        const rows = [];
        const add = row => {
            if (rows.length >= maxRows) throw new AppError('An import may contain up to 5000 rows.', 413);
            rows.push(row);
        };
        const zip = buffer.length >= 4 && buffer.readUInt32LE(0) === 0x04034b50;
        try {
            if (zip) {
                await checkWorkbook(buffer);
                const workbook = new ExcelJS.Workbook();
                await workbook.xlsx.load(buffer);
                const form = workbook.getWorksheet('Quick Entry Form');
                const list =
                    workbook.getWorksheet('Questions List') ||
                    workbook.getWorksheet('Questions') ||
                    (!form && workbook.worksheets[0]);
                if (form) readForm(form, add);
                if (list) {
                    const headers = list.getRow(1).values.slice(1).map(cellText);
                    const decode = listDecoder(headers);
                    list.eachRow((row, n) => {
                        if (n > 1 && row.hasValues)
                            readRecord(add, decode, row.values.slice(1), list.name + ' ' + n);
                    });
                }
            } else {
                if (
                    /\.xlsx$/i.test(filename) ||
                    (!/\.csv$/i.test(filename) && mimeType?.includes('spreadsheetml'))
                ) {
                    throw new AppError('Invalid XLSX workbook.', 400);
                }
                const csv = parseString(new TextDecoder('utf-8', { fatal: true }).decode(buffer), {
                    ignoreEmpty: true
                });
                let decode,
                    number = 0;
                for await (const values of csv) {
                    number++;
                    if (!decode) decode = listDecoder(values);
                    else readRecord(add, decode, values, 'CSV ' + number);
                }
            }
        } catch (e) {
            if (e instanceof AppError) throw e;
            throw new AppError('The workbook or CSV could not be read.', 400);
        }
        if (!rows.length) throw new AppError('The import contains no question rows.', 400);
        const catalog = await topicCatalog();
        return groupQuestions(rows, catalog);
    }
}

function readForm(sheet, add) {
    for (let start = 1; start <= sheet.rowCount; start += 15) {
        const raw = (offset, col) => sheet.findRow(start + offset)?.findCell(col)?.value;
        if (![2, 3, 4, 5, 6, 8, 9, 11, 13].some(n => [2, 3, 6].some(col => raw(n, col) != null))) continue;
        const at = sheet.name + ' ' + (start + 6);
        try {
            const cell = (n, col) => cellText(raw(n, col));
            const shared = n => {
                const first = cell(n, 2), second = cell(n, 3);
                if (first && second && key(first) !== key(second)) throw new Error('The two columns disagree on shared question metadata.');
                return first || second;
            };
            const legacy = !cell(2, 2) && Boolean(cell(6, 6) || cell(9, 6) || cell(11, 6));
            const en = legacy ? 3 : 2,
                hu = legacy ? 6 : 3;
            add({
                at,
                subject: shared(2),
                topic: shared(3),
                bloom: shared(4),
                type: shared(5),
                q_en: cell(6, en),
                q_hu: cell(6, hu),
                correctAns: cell(8, en) || cell(8, hu),
                otherAnswer: cell(8, en) && cell(8, hu) ? cell(8, hu) : undefined,
                optEn: cell(9, en),
                optHu: cell(9, hu),
                expEn: cell(11, en),
                expHu: cell(11, hu),
                db_id: shared(13)
            });
        } catch (e) {
            if (e instanceof AppError) throw e;
            add({ at, error: e.message });
        }
    }
}

function listDecoder(headers) {
    const cols = new Map(headers.map((v, i) => [key(v), i]));
    const localized = cols.has('language');
    const textKeys = ['q_en', 'en', 'question_text_en', 'question_en', 'question_text', 'text_en'];
    if (!cols.has('topic') || !(localized ? cols.has('question_text') : textKeys.some(k => cols.has(k)))) {
        throw new AppError('The question list is missing the topic or question text header.', 400);
    }
    return values => {
        const read = (...keys) => {
            const col = keys.find(k => cols.has(k));
            return col ? cellText(values[cols.get(col)]) : '';
        };
        const lang = key(read('language'));
        const row = {
            db_id: read('db_id'),
            link_id: read('link_id'),
            language: lang,
            subject: read('subject'),
            topic: read('topic'),
            bloom: read('bloom_level', 'bloom'),
            type: key(read('type', 'question_type')),
            correctAns: read('correct_answer', 'correct', 'answer')
        };
        if (localized) {
            if (!['en', 'hu'].includes(lang)) return { ...row, error: 'Select en or hu for the language.' };
            const en = lang === 'en';
            row[en ? 'q_en' : 'q_hu'] = read('question_text');
            row[en ? 'optEn' : 'optHu'] = read('options');
            row[en ? 'expEn' : 'expHu'] = read('explanation');
        } else {
            Object.assign(row, {
                q_en: read(...textKeys),
                q_hu: read('q_hu', 'hu', 'question_text_hu', 'question_hu', 'text_hu'),
                optEn: read('options_en', 'en_options', 'options'),
                optHu: read('options_hu', 'hu_options'),
                expEn: read('explanation_en', 'en_explanation', 'explanation'),
                expHu: read('explanation_hu', 'hu_explanation')
            });
        }
        return row;
    };
}

function readRecord(add, decode, values, at) {
    let row;
    try {
        row = decode(values);
    } catch (e) {
        row = { error: e.message };
    }
    add({ ...row, at });
}

function groupQuestions(rows, catalog) {
    const groups = new Map(),
        editByLink = new Map();
    for (const row of rows) {
        const id = positiveId(row.db_id);
        if (row.link_id && id)
            editByLink.set(
                row.link_id,
                editByLink.has(row.link_id) && editByLink.get(row.link_id) !== id ? null : id
            );
    }
    for (const row of rows) {
        const linked = editByLink.get(row.link_id);
        const id = positiveId(row.db_id) ?? linked;
        if (row.link_id && linked === null) row.error = 'The link identifies different database questions.';
        if (row.db_id && !positiveId(row.db_id)) row.error = 'Invalid DB ID.';
        row.db_id = id;
        row.topic_id = catalog.resolve(row.subject, row.topic);
        if (!row.topic_id && (row.subject || row.topic) && !row.error)
            row.error = 'Invalid, ambiguous or missing topic: ' + (row.topic || row.subject || '');
        const groupKey = id ? 'db:' + id : row.link_id ? 'link:' + row.link_id : Symbol();
        const g = groups.get(groupKey);
        if (!g) {
            groups.set(groupKey, { ...row, languages: new Set(row.language ? [row.language] : []) });
            continue;
        }
        if (g.error) continue;
        if (
            row.error ||
            !row.language ||
            !g.languages.size ||
            g.languages.has(row.language) ||
            (row.topic_id && g.topic_id && row.topic_id !== g.topic_id) ||
            (row.type && g.type && row.type !== g.type) ||
            (row.bloom && g.bloom && row.bloom !== g.bloom)
        ) {
            g.error = row.at + ' · ' + (row.error || 'Conflicting rows for the same question.');
            continue;
        }
        g.topic_id ??= row.topic_id;
        g.languages.add(row.language);
        for (const field of ['q_en', 'q_hu', 'optEn', 'optHu', 'expEn', 'expHu', 'type', 'bloom']) {
            if (row[field]) g[field] = row[field];
        }
        if (g.correctAns && row.correctAns && row.correctAns !== g.correctAns) g.otherAnswer = row.correctAns;
        else if (row.correctAns) g.correctAns = row.correctAns;
    }
    return [...groups.values()];
}

module.exports = new AdminExcelService();
module.exports.checkWorkbook = checkWorkbook;
