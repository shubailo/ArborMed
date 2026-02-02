// Translation Service
// Supports 'GOOGLE' (Unofficial, Free) and 'LIBRE' (Self-Hosted/API)
// Configure via env var: TRANSLATION_PROVIDER=GOOGLE (default) or LIBRE

const googleTranslate = require('google-translate-api-x');

// Config
const PROVIDER = process.env.TRANSLATION_PROVIDER || 'GOOGLE';
const LIBRE_URL = process.env.LIBRETRANSLATE_URL || 'http://localhost:5000';

console.log(`[TranslationService] Using provider: ${PROVIDER}`);
if (PROVIDER === 'LIBRE') console.log(`[TranslationService] LIBRE_URL: ${LIBRE_URL}`);

/**
 * Translate text from one language to another
 */
async function translateText(text, sourceLang, targetLang) {
    if (!text || text.trim() === '') return null;
    if (sourceLang === targetLang) return text;

    try {
        // Try Primary Provider
        if (PROVIDER === 'LIBRE') {
            return await _translateLibre(text, sourceLang, targetLang);
        } else {
            return await _translateGoogle(text, sourceLang, targetLang);
        }
    } catch (error) {
        console.error(`[TranslationService] Primary provider (${PROVIDER}) failed:`, error.message);

        // Fallback Logic
        try {
            const fallbackProvider = PROVIDER === 'LIBRE' ? 'GOOGLE' : 'LIBRE';
            console.log(`[TranslationService] Attempting fallback to: ${fallbackProvider}`);

            if (fallbackProvider === 'LIBRE') {
                return await _translateLibre(text, sourceLang, targetLang);
            } else {
                return await _translateGoogle(text, sourceLang, targetLang);
            }
        } catch (fallbackError) {
            console.error(`[TranslationService] Fallback also failed:`, fallbackError.message);
            throw fallbackError;
        }
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
    const url = `${LIBRE_URL}/translate`;
    console.log(`[LibreTranslate] Requesting: ${url} (${source} -> ${target})`);

    const response = await fetch(url, {
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

        // Relation Analysis Fields
        if (questionData.statement1) {
            translated.statement1 = await safeTrans(questionData.statement1);
        }
        if (questionData.statement2) {
            translated.statement2 = await safeTrans(questionData.statement2);
        }
        if (questionData.link_word) {
            translated.link_word = await safeTrans(questionData.link_word);
        }

        // Matching Fields
        if (questionData.lefts && Array.isArray(questionData.lefts)) {
            translated.lefts = await Promise.all(questionData.lefts.map(l => safeTrans(l)));
        }
        if (questionData.rights && Array.isArray(questionData.rights)) {
            translated.rights = await Promise.all(questionData.rights.map(r => safeTrans(r)));
        }

        return translated;
    } catch (error) {
        console.error('Question translation failed:', error.message);
        throw error;
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
