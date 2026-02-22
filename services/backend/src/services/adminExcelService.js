const ExcelJS = require('exceljs');
const db = require('../config/db');

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
        const subjectsResult = await db.query('SELECT id, name_en FROM topics WHERE parent_id IS NULL ORDER BY name_en ASC');
        const subjects = subjectsResult.rows;

        const topicsResult = await db.query('SELECT id, name_en, parent_id FROM topics WHERE parent_id IS NOT NULL ORDER BY name_en ASC');
        const topics = topicsResult.rows;

        // Populate Reference Sheet for Cascading Dropdowns
        // Col A: Subjects
        subjects.forEach((s, i) => {
            refSheet.getCell(`A${i + 1}`).value = s.name_en;

            // For each subject, create a column of its topics for Named Ranges
            const subjectTopics = topics.filter(t => t.parent_id === s.id).map(t => t.name_en);
            const colLetter = String.fromCharCode(66 + i); // B, C, D...

            subjectTopics.forEach((tName, tIdx) => {
                refSheet.getCell(`${colLetter}${tIdx + 1}`).value = tName;
            });

            // Define Named Range for this subject (sanitized name for Excel)
            const sanitizedName = s.name_en.replace(/[^a-zA-Z0-9]/g, '_');
            if (subjectTopics.length > 0) {
                workbook.definedNames.add(sanitizedName, `Reference!$${colLetter}$1:$${colLetter}$${subjectTopics.length}`);
            } else {
                // Empty range fallback
                refSheet.getCell(`${colLetter}1`).value = "No Sections";
                workbook.definedNames.add(sanitizedName, `Reference!$${colLetter}$1:$${colLetter}$1`);
            }
        });

        workbook.definedNames.add('SubjectsList', `Reference!$A$1:$A$${subjects.length}`);

        // 2. Entry Form Sheet (Visual/Adaptive)
        const formSheet = workbook.addWorksheet('Quick Entry Form');

        // Styling helpers
        const headerStyle = { font: { bold: true, color: { argb: 'FFFFFFFF' } }, fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF4A90E2' } }, alignment: { horizontal: 'center' } };
        const labelStyle = { font: { bold: true }, fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF5F7F9' } } };
        const borderStyle = { top: { style: 'thin' }, left: { style: 'thin' }, bottom: { style: 'thin' }, right: { style: 'thin' } };

        formSheet.getColumn('A').width = 20;
        formSheet.getColumn('B').width = 40;
        formSheet.getColumn('C').width = 40;

        for (let i = 0; i < 20; i++) { // Generate 20 entry blocks
            const startRow = (i * 15) + 1;

            // Block Header
            const hRow = formSheet.getRow(startRow);
            hRow.values = [`QUESTION #${i + 1}`, 'ENGLISH CONTENT', 'HUNGARIAN CONTENT'];
            hRow.eachCell(cell => { cell.style = headerStyle; cell.border = borderStyle; });
            formSheet.mergeCells(startRow, 1, startRow + 1, 1);

            // Fields
            const fields = [
                { label: 'Subject', key: 'subject', validation: { type: 'list', formulae: ['SubjectsList'] } },
                { label: 'Topic (Section)', key: 'topic' }, // Will handle dynamic validation later
                { label: 'Bloom Level', validation: { type: 'list', formulae: ['"1,2,3,4,5,6"'] } },
                { label: 'Type', validation: { type: 'list', formulae: ['"single_choice,multiple_choice,true_false,matching,ordering,case_study"'] } },
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
                    formSheet.getCell(currentRow, 2).dataValidation = {
                        type: 'list',
                        allowBlank: true,
                        formulae: [`=INDIRECT(SUBSTITUTE(${subjectCellAddr}, " ", "_"))`]
                    };
                    formSheet.getCell(currentRow, 3).dataValidation = {
                        type: 'list',
                        allowBlank: true,
                        formulae: [`=INDIRECT(SUBSTITUTE(${subjectCellAddr}, " ", "_"))`]
                    };
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
            'db_id', 'link_id', 'language', 'subject', 'topic',
            'question_text', 'bloom_level', 'type', 'correct_answer',
            'options', 'explanation'
        ];
        dataSheet.addRow(headers);
        dataSheet.getRow(1).font = { bold: true };
        dataSheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE0E0E0' } };

        for (let i = 2; i <= 500; i++) {
            dataSheet.getCell(`C${i}`).dataValidation = { type: 'list', formulae: ['"en,hu"'] };
            dataSheet.getCell(`D${i}`).dataValidation = { type: 'list', formulae: ['SubjectsList'] };
            dataSheet.getCell(`E${i}`).dataValidation = {
                type: 'list', allowBlank: true,
                formulae: [`=INDIRECT(SUBSTITUTE(D${i}, " ", "_"))`]
            };
            dataSheet.getCell(`G${i}`).dataValidation = { type: 'list', formulae: ['"1,2,3,4,5,6"'] };
            dataSheet.getCell(`H${i}`).dataValidation = { type: 'list', formulae: ['"single_choice,multiple_choice,true_false,matching,ordering,case_study"'] };
        }

        dataSheet.columns.forEach(col => { col.width = 20; });

        return workbook;
    }

    /**
     * Parses an uploaded file (Excel or CSV) and returns a grouped list of questions.
     * @param {Buffer} buffer - File buffer
     * @param {string} mimeType - File mime type
     */
    async parseFile(buffer, mimeType) {
        const workbook = new ExcelJS.Workbook();
        let rows = [];

        if (mimeType.includes('spreadsheetml') || mimeType.includes('excel') || (buffer.length > 4 && buffer[0] === 0x50 && buffer[1] === 0x4B)) {
            await workbook.xlsx.load(buffer);
            const formSheet = workbook.getWorksheet('Quick Entry Form');
            const listSheet = workbook.getWorksheet('Questions List') || workbook.getWorksheet('Questions') || workbook.worksheets[0];

            if (formSheet) {
                // Parse Block-based Form (Standardized 15-row blocks)
                for (let i = 0; i < 200; i++) {
                    const startRow = (i * 15) + 1;
                    const subject = formSheet.getCell(startRow + 2, 3).value; // Col C
                    if (!subject) continue;

                    rows.push({
                        link_id: i + 1,
                        subject: subject,
                        topic: formSheet.getCell(startRow + 3, 3).value, // Col C
                        bloom: formSheet.getCell(startRow + 4, 3).value, // Col C
                        type: formSheet.getCell(startRow + 5, 3).value, // Col C
                        q_en: formSheet.getCell(startRow + 6, 3).value, // Col C
                        q_hu: formSheet.getCell(startRow + 6, 6).value, // Col F
                        correctAns: formSheet.getCell(startRow + 8, 3).value, // Col C
                        optEn: formSheet.getCell(startRow + 9, 3).value, // Col C
                        optHu: formSheet.getCell(startRow + 9, 6).value, // Col F
                        expEn: formSheet.getCell(startRow + 11, 3).value, // Col C
                        expHu: formSheet.getCell(startRow + 11, 6).value, // Col F
                        db_id: formSheet.getCell(startRow + 13, 3).value // Col C
                    });
                }
            } else {
                // Parse Row-based List
                listSheet.eachRow((row, rowNumber) => {
                    if (rowNumber === 1) return; // Skip header
                    const lang = row.getCell(3).value?.toString().toLowerCase();

                    rows.push({
                        db_id: row.getCell(1).value,
                        link_id: row.getCell(2).value,
                        language: lang,
                        subject: row.getCell(4).value,
                        topic: row.getCell(5).value,
                        // If language column exists, we route content based on it
                        // Otherwise (legacy format), we use fixed columns
                        q_en: lang === 'en' ? row.getCell(6).value : (lang ? null : row.getCell(3).value),
                        q_hu: lang === 'hu' ? row.getCell(6).value : (lang ? null : row.getCell(4).value),
                        bloom: row.getCell(7).value,
                        type: row.getCell(8).value,
                        correctAns: row.getCell(9).value,
                        optEn: lang === 'en' ? row.getCell(10).value : (lang ? null : row.getCell(9).value),
                        optHu: lang === 'hu' ? row.getCell(10).value : (lang ? null : row.getCell(10).value),
                        expEn: lang === 'en' ? row.getCell(11).value : (lang ? null : row.getCell(11).value),
                        expHu: lang === 'hu' ? row.getCell(11).value : (lang ? null : row.getCell(12).value)
                    });
                });
            }
        } else {
            // Fallback for CSV
            const csvData = buffer.toString('utf-8');
            const lines = csvData.split(/\r?\n/).filter(l => l.trim().length > 0);
            for (let i = 1; i < lines.length; i++) {
                const matches = [...lines[i].matchAll(/(?:^|,)(?:"([^"]*)"|([^,]*))/g)];
                const v = matches.map(m => m[1] !== undefined ? m[1] : (m[2] || ''));
                if (v.length < 5) continue;
                rows.push({
                    q_en: v[0], q_hu: v[1], topic: v[2], bloom: v[3], type: v[4],
                    correctAns: v[5], optEn: v[6], optHu: v[7], expEn: v[8], expHu: v[9]
                });
            }
        }

        // Fetch topics for mapping (Map by name_en)
        const topicsResult = await db.query('SELECT id, name_en FROM topics');
        const topicMap = {};
        topicsResult.rows.forEach(t => {
            topicMap[t.name_en.toLowerCase()] = t.id;
            topicMap[t.id] = t.id;
        });

        // Grouping & Merging Logic
        const groups = {};
        rows.forEach((r, idx) => {
            const key = r.db_id ? `db_${r.db_id}` : (r.link_id ? `link_${r.link_id}` : `temp_${idx}`);
            if (!groups[key]) {
                groups[key] = { ...r, topic_id: topicMap[r.topic?.toString().toLowerCase()] || 0 };
            } else {
                const g = groups[key];
                g.q_en = r.q_en || g.q_en;
                g.q_hu = r.q_hu || g.q_hu;
                g.correctAns = r.correctAns || g.correctAns;
                g.optEn = r.optEn || g.optEn;
                g.optHu = r.optHu || g.optHu;
                g.expEn = r.expEn || g.expEn;
                g.expHu = r.expHu || g.expHu;
                if (!g.topic_id) g.topic_id = topicMap[r.topic?.toString().toLowerCase()] || 0;
            }
        });

        return Object.values(groups);
    }
}

module.exports = new AdminExcelService();
