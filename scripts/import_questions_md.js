const fs = require('fs');
const path = require('path');

/**
 * 🌿 ArborMed Content Import Pipeline
 * Parses Hungarian Medical Board exam questions from `Tavaszi kórélettan kérdések.md`
 * and transforms them into structured ArborMed question entities.
 */

const INPUT_MD_PATH = path.join(__dirname, '../Tavaszi kórélettan kérdések.md');
const OUTPUT_JSON_PATH = path.join(
    __dirname,
    '../services/backend/src/data/questions/pathophysiology/tavaszi_imported.json'
);

// Map section titles & keywords to ArborMed topic slugs
function detectTopicSlug(sectionTitle, questionText) {
    const combined = `${sectionTitle} ${questionText}`.toLowerCase();
    if (combined.includes('vese') || combined.includes('gfr') || combined.includes('tubul') || combined.includes('uraemi') || combined.includes('nephr') || combined.includes('anion gap') || combined.includes('acidózis') || combined.includes('alkalózis')) {
        return 'renal-homeostasis';
    }
    if (combined.includes('szív') || combined.includes('keringés') || combined.includes('infarct') || combined.includes('vérnyomás') || combined.includes('hypertonia') || combined.includes('arrhythmi')) {
        return 'cardiovascular';
    }
    if (combined.includes('reflux') || combined.includes('gerd') || combined.includes('gyomor') || combined.includes('máj') || combined.includes('icterus') || combined.includes('pancrea') || combined.includes('bél') || combined.includes('fekély') || combined.includes('helicobacter')) {
        return 'gastrointestinal';
    }
    if (combined.includes('vér') || combined.includes('anaemia') || combined.includes('leukocyt') || combined.includes('thromb') || combined.includes('alvadás') || combined.includes('erythro')) {
        return 'haematology';
    }
    if (combined.includes('éhezés') || combined.includes('elhízás') || combined.includes('vitamin') || combined.includes('marasmus') || combined.includes('kwashiorkor') || combined.includes('skorbut') || combined.includes('rachitis')) {
        return 'nutrition';
    }
    if (combined.includes('diabetes') || combined.includes('glükóz') || combined.includes('inzulin') || combined.includes('anyagcsere') || combined.includes('ketoacid')) {
        return 'energy-balance';
    }
    return 'renal-homeostasis';
}

function detectBloomLevel(text) {
    const lower = text.toLowerCase();
    // Clinical vignette / patient scenario -> Level 3 or 4
    if (lower.includes('beteg') || lower.includes('jelentkezik') || lower.includes('osztályon') || lower.includes('esetén') || lower.includes('abg:') || lower.includes('laboratóriumi')) {
        return lower.includes('mi a primer') || lower.includes('legvalószínűbb háttér') || lower.includes('szövődményeként') ? 4 : 3;
    }
    // Deep mechanism / cause-effect
    if (lower.includes('hátterében') || lower.includes('mechanizmus') || lower.includes('mert')) {
        return 3;
    }
    // Recall / definition ("jellemző", "nem jellemző")
    return 1;
}

function cleanText(text) {
    if (!text) return '';
    return text
        .replace(/\\/g, '')
        .replace(/\*\*/g, '')
        .replace(/\t+/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

function parseMarkdownQuestions(content) {
    const lines = content.split('\n');
    const questions = [];

    let currentSection = 'Vese / pH / só-víz / kálium kórélettan';
    let currentQ = null;
    let mode = 'NONE'; // 'QUESTION', 'OPTIONS', 'RELATION'

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line) continue;

        // Section header detection
        if (line.startsWith('#')) {
            currentSection = cleanText(line.replace(/^[#\s\d\\.]+/, ''));
            continue;
        }

        // Subheader detection
        if (line.startsWith('##')) {
            continue;
        }

        // Question start detection: e.g. "1. Akut hyperventilatio esetén" or "12. A veseartéria szűkülete esetén"
        const qStartMatch = line.match(/^(\d+)\.\s+(.+)$/);
        const isOption = line.match(/^([a-eA-E]|\d)[\.)\s]/);
        const isAnswerLine = line.toLowerCase().startsWith('helyes:');

        if (qStartMatch && !isAnswerLine && (!currentQ || currentQ.correctAnswer || currentQ.options.length >= 2)) {
            // Flush previous question if valid
            if (currentQ && currentQ.options.length >= 2 && currentQ.correctAnswer) {
                questions.push(finalizeQuestion(currentQ));
            }

            const qText = cleanText(qStartMatch[2]);
            // Check if this line is a single-line relation analysis (e.g. "1. Coma-állapotokban... MERT... D")
            const relationInline = qText.match(/(.+?)\s+MERT\s+(.+?)\s+([A-E])\s*$/i);
            if (relationInline) {
                questions.push(finalizeQuestion({
                    section: currentSection,
                    questionText: `${relationInline[1]} MERT ${relationInline[2]}`,
                    options: [
                        { id: 'a', text: 'igaz / igaz - összefügg' },
                        { id: 'b', text: 'igaz / igaz - összefüggés nincs' },
                        { id: 'c', text: 'igaz / hamis' },
                        { id: 'd', text: 'hamis / igaz' },
                        { id: 'e', text: 'hamis / hamis' },
                    ],
                    correctAnswer: relationInline[3].toLowerCase(),
                    type: 'relation_analysis'
                }));
                currentQ = null;
                continue;
            }

            currentQ = {
                section: currentSection,
                questionText: qText,
                options: [],
                correctAnswer: null,
                type: 'single_choice'
            };
            mode = 'OPTIONS';
            continue;
        }

        // Option line detection: e.g. "a. ...", "b. ...", "1. ...", "2. ..."
        if (currentQ) {
            // Answer line detection: e.g. "Helyes: B" or "Helyes: **C** (2,4)"
            if (isAnswerLine) {
                const ansMatch = line.match(/helyes:\s*(\*\*)?([A-Fa-f])/i);
                if (ansMatch) {
                    currentQ.correctAnswer = ansMatch[2].toLowerCase();
                }
                continue;
            }

            // Option lines: "a. az artériás vér...", "**b. az artériás vér...**"
            const optLetterMatch = line.match(/^\*?\*?([a-eA-E])[\.\)]\s*(.+?)\*?\*?$/);
            if (optLetterMatch) {
                const optId = optLetterMatch[1].toLowerCase();
                const optText = cleanText(optLetterMatch[2]);
                currentQ.options.push({ id: optId, text: optText });
                if (line.includes('**') && !currentQ.correctAnswer) {
                    currentQ.correctAnswer = optId;
                }
                continue;
            }

            // Numbered option lines: "1. vesekeringés csökkenésekor"
            const optNumMatch = line.match(/^(\d+)[\.\)]\s*(.+)$/);
            if (optNumMatch) {
                const optId = optNumMatch[1];
                const optText = cleanText(optNumMatch[2]);
                currentQ.options.push({ id: optId, text: optText });
                currentQ.type = 'multiple_choice';
                continue;
            }

            // Multiline continuation of question text or options
            if (currentQ.options.length === 0) {
                currentQ.questionText += ' ' + cleanText(line);
            }
        }
    }

    // Flush last question
    if (currentQ && currentQ.options.length >= 2 && currentQ.correctAnswer) {
        questions.push(finalizeQuestion(currentQ));
    }

    return questions;
}

function finalizeQuestion(q) {
    const topicSlug = detectTopicSlug(q.section, q.questionText);
    const bloomLevel = detectBloomLevel(q.questionText);

    let formattedOptions = q.options;
    let correctAnswer = q.correctAnswer;

    // For numbered multiple-choice (1,2,3,4) questions where Hungarian answer is A, B, C, D, E
    if (q.type === 'multiple_choice' && q.options.length >= 4) {
        // Provide standard multiple choice options
        formattedOptions = [
            { id: 'a', text: '1., 2. és 3. válasz helyes' },
            { id: 'b', text: '1. és 3. válasz helyes' },
            { id: 'c', text: '2. és 4. válasz helyes' },
            { id: 'd', text: 'csak a 4. válasz helyes' },
            { id: 'e', text: 'mind a 4 válasz helyes' }
        ];
        // Combine statements into question text
        const statements = q.options.map(o => `${o.id}. ${o.text}`).join('\n');
        q.questionText = `${q.questionText}\n\n${statements}`;
    }

    return {
        question_text_hu: q.questionText,
        question_text_en: q.questionText, // Bilingual seed; can be enriched via translation service
        question_type: 'single_choice',
        bloom_level: bloomLevel,
        difficulty: bloomLevel >= 3 ? 4 : 2,
        options: {
            hu: formattedOptions,
            en: formattedOptions
        },
        correct_answer: correctAnswer || 'a',
        explanation_hu: `Helyes válasz: ${correctAnswer?.toUpperCase()}. Részletes téma: ${q.section}.`,
        explanation_en: `Correct answer: ${correctAnswer?.toUpperCase()}. Topic: ${q.section}.`,
        topic_slug: topicSlug,
        active: true
    };
}

function run() {
    console.log('📖 Reading questions markdown from:', INPUT_MD_PATH);
    if (!fs.existsSync(INPUT_MD_PATH)) {
        console.error('❌ Input file not found:', INPUT_MD_PATH);
        process.exit(1);
    }

    const content = fs.readFileSync(INPUT_MD_PATH, 'utf8');
    const parsed = parseMarkdownQuestions(content);

    console.log(`✅ Successfully parsed ${parsed.length} medical board questions!`);

    // Topic distribution summary
    const distribution = {};
    parsed.forEach(q => {
        distribution[q.topic_slug] = (distribution[q.topic_slug] || 0) + 1;
    });

    console.log('\n📊 Questions distribution by topic:');
    for (const [topic, count] of Object.entries(distribution)) {
        console.log(`   - ${topic}: ${count} questions`);
    }

    // Ensure output directory exists
    const outDir = path.dirname(OUTPUT_JSON_PATH);
    if (!fs.existsSync(outDir)) {
        fs.mkdirSync(outDir, { recursive: true });
    }

    fs.writeFileSync(OUTPUT_JSON_PATH, JSON.stringify(parsed, null, 2), 'utf8');
    console.log(`\n💾 Saved structured questions to: ${OUTPUT_JSON_PATH}`);

    return parsed;
}

if (require.main === module) {
    run();
}

module.exports = { parseMarkdownQuestions, detectTopicSlug, detectBloomLevel };
