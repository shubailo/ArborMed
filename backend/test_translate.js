const translationService = require('./src/services/translationService');

async function test() {
    console.log("Testing translation...");
    try {
        const text = "Study Break";
        const result = await translationService.translateText(text, 'en', 'hu');
        console.log(`Original: ${text}`);
        console.log(`Translated: ${result}`);
    } catch (e) {
        console.error("Test failed:", e);
    }
}

test();
