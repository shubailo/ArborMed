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

        // 1. Instructions Sheet
        const instructionSheet = workbook.addWorksheet('Instructions');
        instructionSheet.columns = [
            { header: 'Column', key: 'column', width: 20 },
            { header: 'Requirement', key: 'req', width: 20 },
            { header: 'Description', key: 'desc', width: 80 }
        ];

        instructionSheet.addRows([
            ['db_id', 'Optional', 'Leave BLANK for new questions. Provide a valid ID to UPDATE an existing question.'],
            ['link_id', 'Optional', 'Use the same number for two rows (one EN, one HU) to merge them into a single question.'],
            ['question_text_en', 'Required*', 'The main question in English.'],
            ['question_text_hu', 'Required*', 'The main question in Hungarian.'],
            ['topic', 'Required', 'Select from dropdown. This links to the medical category.'],
            ['bloom_level', 'Required', 'Cognitive difficulty level (1-6).'],
            ['type', 'Required', 'Question format (e.g., single_choice, multiple_choice).'],
            ['correct_answer', 'Required', 'The correct choice(s). For multiple choice, use ; separator.'],
            ['options_en', 'Required', 'Possible answers in English. SEPARATE WITH ; (e.g., Apple;Banana;Pear)'],
            ['options_hu', 'Required', 'Possible answers in Hungarian. SEPARATE WITH ;'],
            ['explanation_en', 'Optional', 'Why the answer is correct (English).'],
            ['explanation_hu', 'Optional', 'Why the answer is correct (Hungarian).']
        ]);

        instructionSheet.getRow(1).font = { bold: true };

        // 2. Data Sheet
        const dataSheet = workbook.addWorksheet('Questions');
        const headers = [
            'db_id', 'link_id', 'question_text_en', 'question_text_hu',
            'topic', 'bloom_level', 'type', 'correct_answer',
            'options_en', 'options_hu', 'explanation_en', 'explanation_hu'
        ];
        dataSheet.addRow(headers);
        dataSheet.getRow(1).font = { bold: true };
        dataSheet.getRow(1).fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FFE0E0E0' }
        };

        // Fetch topics for dropdown
        const topicsResult = await db.query('SELECT name_en FROM topics ORDER BY name_en ASC');
        const topicNames = topicsResult.rows.map(r => r.name_en);

        // Hidden reference sheet for dropdowns (topics might be long)
        const refSheet = workbook.addWorksheet('Reference');
        topicNames.forEach((name, i) => {
            refSheet.getCell(`A${i + 1}`).value = name;
        });
        workbook.definedNames.add('TopicsList', `Reference!$A$1:$A$${topicNames.length}`);

        // Add example rows
        dataSheet.addRow([
            null, 1, 'What is the powerhouse of the cell?', 'Mi a sejt energiaközpontja?',
            topicNames[0] || 'General', 1, 'single_choice', 'Mitochondria',
            'Mitochondria;Nucleus;Ribosome;Cytoplasm', 'Mitokondrium;Sejtmag;Riboszóma;Citoplazma',
            'Mitochondria produce ATP.', 'A mitokondriumok termelik az ATP-t.'
        ]);

        dataSheet.addRow([
            null, 2, 'Which are types of leukocytes? (Select multiple)', 'Melyek a leukociták típusai? (Válassz többet)',
            topicNames[0] || 'General', 2, 'multiple_choice', 'Neutrophils;Lymphocytes',
            'Neutrophils;Lymphocytes;Erythrocytes;Platelets', 'Neutrofilek;Limfociták;Eritrociták;Vérlemezkék',
            'Neutrophils and Lymphocytes are white blood cells.', 'A neutrofilek és a limfociták fehérvérsejtek.'
        ]);

        // Apply Data Validations for 1000 rows
        for (let i = 2; i <= 1001; i++) {
            // Topic Dropdown
            dataSheet.getCell(`E${i}`).dataValidation = {
                type: 'list',
                allowBlank: true,
                formulae: ['TopicsList']
            };

            // Bloom Level Dropdown
            dataSheet.getCell(`F${i}`).dataValidation = {
                type: 'list',
                allowBlank: true,
                formulae: ['"1,2,3,4,5,6"']
            };

            // Type Dropdown
            dataSheet.getCell(`G${i}`).dataValidation = {
                type: 'list',
                allowBlank: true,
                formulae: ['"single_choice,multiple_choice,true_false,matching,ordering,case_study"']
            };
        }

        dataSheet.columns.forEach(col => { col.width = 25; });

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

        if (mimeType.includes('spreadsheetml') || mimeType.includes('excel')) {
            await workbook.xlsx.load(buffer);
            const sheet = workbook.getWorksheet('Questions') || workbook.worksheets[0];

            sheet.eachRow((row, rowNumber) => {
                if (rowNumber === 1) return; // Skip header
                rows.push({
                    db_id: row.getCell(1).value,
                    link_id: row.getCell(2).value,
                    q_en: row.getCell(3).value,
                    q_hu: row.getCell(4).value,
                    topic: row.getCell(5).value,
                    bloom: row.getCell(6).value,
                    type: row.getCell(7).value,
                    correctAns: row.getCell(8).value,
                    optEn: row.getCell(9).value,
                    optHu: row.getCell(10).value,
                    expEn: row.getCell(11).value,
                    expHu: row.getCell(12).value
                });
            });
        } else {
            // Fallback for CSV (Simple parsing)
            const csvData = buffer.toString('utf-8');
            const lines = csvData.split(/\r?\n/).filter(l => l.trim().length > 0);
            for (let i = 1; i < lines.length; i++) {
                const matches = [...lines[i].matchAll(/(?:^|,)(?:"([^"]*)"|([^,]*))/g)];
                const v = matches.map(m => m[1] !== undefined ? m[1] : (m[2] || ''));
                if (v.length < 5) continue;
                rows.push({
                    db_id: null,
                    link_id: null,
                    q_en: v[0], q_hu: v[1], topic: v[2], bloom: v[3], type: v[4],
                    correctAns: v[5], optEn: v[6], optHu: v[7], expEn: v[8], expHu: v[9]
                });
            }
        }

        // Fetch topics for mapping
        const topicsResult = await db.query('SELECT id, name_en FROM topics');
        const topicMap = {};
        topicsResult.rows.forEach(t => {
            topicMap[t.name_en.toLowerCase()] = t.id;
            topicMap[t.id] = t.id; // Also allow raw IDs
        });

        // Group rows by db_id OR link_id
        const groups = {};
        rows.forEach((r, idx) => {
            const key = r.db_id ? `db_${r.db_id}` : (r.link_id ? `link_${r.link_id}` : `temp_${idx}`);
            if (!groups[key]) {
                groups[key] = { ...r, topic_id: topicMap[r.topic?.toString().toLowerCase()] || 0 };
            } else {
                // Merge data (keep existing if new is empty)
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
