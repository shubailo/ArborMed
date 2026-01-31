// Translation Service
// Supports 'GOOGLE' (Unofficial, Free) and 'LIBRE' (Self-Hosted/API)
// Configure via env var: TRANSLATION_PROVIDER=GOOGLE (default) or LIBRE

const googleTranslate = require('google-translate-api-x');

// Config
const PROVIDER = process.env.TRANSLATION_PROVIDER || 'GOOGLE';
const LIBRE_URL = process.env.LIBRETRANSLATE_URL || 'http://localhost:5000';

console.log(`[TranslationService] Using provider: ${PROVIDER}`);

/**
 * Translate text from one language to another
 */
async function translateText(text, sourceLang, targetLang) {
    if (!text || text.trim() === '') return null;
    if (sourceLang === targetLang) return text;

    try {
        if (PROVIDER === 'LIBRE') {
            return await _translateLibre(text, sourceLang, targetLang);
        } else {
            return await _translateGoogle(text, sourceLang, targetLang);
        }
    } catch (error) {
        console.error(`Translation failed (${PROVIDER}):`, error.message);
        return `[${targetLang.toUpperCase()}] ${text}`; // Fallback
    }
}

// implementation: Google
async function _translateGoogle(text, source, target) {
    const res = await googleTranslate(text, {
        from: source,
        to: target,
        forceBatch: false
    });
    return res.text;
}

// implementation: LibreTranslate (Self-Hosted)
async function _translateLibre(text, source, target) {
    const response = await fetch(`${LIBRE_URL}/translate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            q: text,
            source: source,
            target: target,
            format: 'text'
        })
    });

    if (!response.ok) {
        throw new Error(`LibreTranslate API ${response.status}: ${response.statusText}`);
    }

    const data = await response.json();
    return data.translatedText;
}

/**
 * Translate an entire question object with all its fields
 */
async function translateQuestion(questionData, sourceLang, targetLang) {
    try {
        const translated = {};

        // Helper to translate safely
        const safeTrans = (t) => translateText(t, sourceLang, targetLang);

        if (questionData.questionText) {
            translated.questionText = await safeTrans(questionData.questionText);
        }

        if (questionData.options && Array.isArray(questionData.options)) {
            translated.options = await Promise.all(questionData.options.map(o => safeTrans(o)));
        }

        if (questionData.explanation) {
            translated.explanation = await safeTrans(questionData.explanation);
        }

        return translated;
    } catch (error) {
        console.error('Question translation failed:', error.message);
        return {};
    }
}

async function batchTranslate(texts, sourceLang, targetLang) {
    try {
        return await Promise.all(texts.map(t => translateText(t, sourceLang, targetLang)));
    } catch (error) {
        return texts.map(t => `[${targetLang.toUpperCase()}] ${t}`);
    }
}

module.exports = {
    translateText,
    translateQuestion,
    batchTranslate
};
