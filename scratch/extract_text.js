const fs = require('fs');
const xml = fs.readFileSync('docx_content/word/document.xml', 'utf8');
const text = xml.replace(/<[^>]+>/g, '').trim();
console.log(text);
