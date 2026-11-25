const fs = require('fs');
try {
    const xml = fs.readFileSync('docx_content/word/document.xml', 'utf8');
    // Remove tags and replace them with spaces to avoid joining words
    const text = xml.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
    console.log(text);
} catch (e) {
    console.error(e);
}
