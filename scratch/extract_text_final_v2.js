const fs = require('fs');
try {
    const xml = fs.readFileSync('docx_content/word/document.xml', 'utf8');
    const text = xml.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
    fs.writeFileSync('scratch/extracted_doc_text_utf8.txt', text, 'utf8');
} catch (e) {
    console.error(e);
}
