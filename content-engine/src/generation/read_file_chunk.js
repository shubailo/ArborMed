const fs = require('fs');
const file = process.argv[2];
const start = parseInt(process.argv[3]) || 0;
const length = parseInt(process.argv[4]) || 15000;

try {
    const buffer = fs.readFileSync(file);
    let text;
    // Simple encoding check (BOM)
    if (buffer.length >= 2 && buffer[0] === 0xFF && buffer[1] === 0xFE) {
        text = buffer.toString('utf16le');
    } else {
        text = buffer.toString('utf8');
    }

    // Clean up text: remove undefined chars, collapse whitespace
    const cleanText = text.replace(/\ufffd/g, '')
        .replace(/\r\n/g, '\n')
        .replace(/\n\s*\n/g, '\n') // Collapse multiple newlines
        .replace(/[ \t]+/g, ' ');     // Collapse multiple spaces (preserve newlines)

    const outputFile = process.argv[5];
    if (outputFile) {
        fs.writeFileSync(outputFile, cleanText.substring(start, start + length));
    } else {
        console.log(cleanText.substring(start, start + length));
    }
} catch (err) {
    console.error("Error:", err);
}
