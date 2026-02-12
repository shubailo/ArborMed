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
    let end = start + length;

    // Smart boundary: search forward for next sentence end if we are not at EOF
    if (end < cleanText.length) {
        const remainingText = cleanText.substring(end, end + 500); // 500 char safety window
        const boundaries = [
            remainingText.indexOf('. '),
            remainingText.indexOf('! '),
            remainingText.indexOf('? '),
            remainingText.indexOf('.\n'),
            remainingText.indexOf('!\n'),
            remainingText.indexOf('?\n'),
            remainingText.indexOf('\n')
        ].filter(idx => idx !== -1);

        if (boundaries.length > 0) {
            const nextBoundary = Math.min(...boundaries);
            // Include the punctuation/newline itself
            end += (nextBoundary + 1);
        }
    }

    const chunk = cleanText.substring(start, end);

    if (outputFile) {
        fs.writeFileSync(outputFile, chunk);
        console.log(`Wrote ${chunk.length} characters to ${outputFile}`);
    } else {
        console.log(chunk);
    }
} catch (err) {
    console.error("Error:", err);
}
