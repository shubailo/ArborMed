const fs = require('fs');
const path = require('path');
const pdf = require('pdf-parse');
const readline = require('readline');
require('dotenv').config();

// Configuration
const BOOK_DIR = path.join(__dirname, '../../book');
const QUESTIONS_DIR = path.join(__dirname, '../src/data/questions/pathophysiology');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

const askQuestion = (query) => new Promise(resolve => rl.question(query, resolve));

async function main() {
    console.log("🧠 AGOOM Question Factory 🧠");
    console.log("--------------------------------");

    // 1. Select PDF
    const files = fs.readdirSync(BOOK_DIR).filter(f => f.endsWith('.pdf'));
    if (files.length === 0) {
        console.error("No PDFs found in " + BOOK_DIR);
        process.exit(1);
    }

    console.log("Available Books:");
    files.forEach((f, i) => console.log(`${i + 1}. ${f}`));

    const fileIndex = await askQuestion("\nSelect book number: ");
    const filename = files[parseInt(fileIndex) - 1];

    if (!filename) {
        console.error("Invalid selection.");
        process.exit(1);
    }

    // 2. Select Bloom Level
    console.log("\nTarget Bloom Level:");
    console.log("1. Recall (Basics)");
    console.log("2. Application (Clinical Cases)");
    console.log("3. Analysis (Diagnosis/Mechanisms)");
    console.log("4. Evaluation (Treatment Choices)");

    const levelInput = await askQuestion("Select level (1-4): ");
    const bloomMap = { '1': 'Recall', '2': 'Application', '3': 'Analysis', '4': 'Evaluation' };
    const bloomLevel = bloomMap[levelInput] || 'Recall';

    // 3. Select Topic to Append To
    const topicFiles = fs.readdirSync(QUESTIONS_DIR).filter(f => f.endsWith('.json'));
    console.log("\nTarget Topic File:");
    console.log("0. [CREATE NEW]");
    topicFiles.forEach((f, i) => console.log(`${i + 1}. ${f}`));

    const topicIndex = await askQuestion("Select topic number: ");
    let targetFile;
    if (topicIndex === '0') {
        const newName = await askQuestion("Enter new filename (e.g. respiratory.json): ");
        targetFile = newName.endsWith('.json') ? newName : newName + '.json';
    } else {
        targetFile = topicFiles[parseInt(topicIndex) - 1];
    }

    // 4. Processing


    // 5. Process
    console.log(`\nReading ${filename}...`);
    const dataBuffer = fs.readFileSync(path.join(BOOK_DIR, filename));
    const data = await pdf(dataBuffer);

    // Extract a meaningful chunk (e.g., from the middle or a specific chapter if we added selection)
    const fullText = data.text;
    const start = Math.floor(fullText.length * 0.1); // Start 10% in to skip TOC
    // Take a larger chunk for the Agent to process
    const chunkDetails = fullText.substring(start, start + 8000);

    console.log("\n--- EXTRACTED TEXT FOR AGENT ---");
    console.log("--------------------------------");
    console.log(chunkDetails);
    console.log("--------------------------------");
    console.log("\n[AGENT INSTRUCTION]");
    console.log(`Please generate 5 multiple choice questions from the text above.`);
    console.log(`Target Level: ${bloomLevel}`);
    console.log(`Target File: ${targetFile}`);
    console.log("Format: JSON array with 'text', 'options', 'correct_answer', 'explanation', 'bloom_level'.");

    rl.close();
}

main();
