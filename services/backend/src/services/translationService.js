// Translation Service
// Supports 'GOOGLE' (Unofficial, Free) and 'LIBRE' (Self-Hosted/API)
// Configure via env var: TRANSLATION_PROVIDER=GOOGLE (default) or LIBRE

const googleTranslate = require('google-translate-api-x');
const logger = require('../utils/logger');
const AppError = require('../utils/AppError');

// Config
const PROVIDER = (process.env.TRANSLATION_PROVIDER || 'GOOGLE').trim().toUpperCase();
const LIBRE_URL = process.env.LIBRETRANSLATE_URL || 'http://localhost:5000';

logger.info(`[TranslationService] Using provider: ${PROVIDER}`);

const providers = {
    GOOGLE: _translateGoogle,
    LIBRE: _translateLibre,
};

async function translateText(text, sourceLang, targetLang, deadline) {
    if (!text || text.trim() === '') return null;
    if (sourceLang === targetLang) return text;

    const fallback = PROVIDER === 'LIBRE' ? 'GOOGLE' : 'LIBRE';
    for (const name of [PROVIDER, fallback]) {
        if (deadline?.aborted) break;
        const timeout = AbortSignal.timeout(8000);
        const signal = deadline ? AbortSignal.any([deadline, timeout]) : timeout;
        try {
            const value = await providers[name](text, sourceLang, targetLang, signal);
            if (typeof value === 'string' && value.trim()) return value;
            logger.error(`[TranslationService] ${name} returned no translation`);
        } catch {
            const reason = signal.aborted ? 'cancelled or timed out' : 'request failed';
            logger.error(`[TranslationService] ${name}: ${reason}`);
        }
    }
    throw new AppError('Translation service unavailable. Please try again.', 502);
}

// implementation: Google
async function _translateGoogle(text, source, target, signal) {
    const res = await googleTranslate(text, {
        from: source,
        to: target,
        forceBatch: false,
        requestOptions: {signal}
    });
    return res.text;
}

// implementation: LibreTranslate (Self-Hosted)
async function _translateLibre(text, source, target, signal) {
    const url = `${LIBRE_URL}/translate`;

    const response = await fetch(url, {
        method: 'POST',
        signal,
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
    const scalarFields = ['questionText', 'explanation', 'statement1', 'statement2', 'link_word'];
    const listFields = ['options', 'lefts', 'rights'];
    if (!questionData || typeof questionData !== 'object' || Array.isArray(questionData)) {
        throw new AppError('A question object is required.', 400);
    }
    const fields = [];
    for (const key of scalarFields) {
        const value = questionData[key];
        if (value == null || value === '') continue;
        if (typeof value !== 'string') throw new AppError('Invalid question text field.', 400);
        if (value.trim()) fields.push([key, value]);
    }
    for (const key of listFields) {
        const values = questionData[key];
        if (values == null) continue;
        if (!Array.isArray(values) || values.some(text => typeof text !== 'string')) {
            throw new AppError('Invalid question option list.', 400);
        }
        fields.push([key, values]);
    }
    const translations = new Map();
    for (const [, value] of fields) {
        for (const text of Array.isArray(value) ? value : [value]) {
            if (text.trim()) translations.set(text, null);
        }
    }
    if (!translations.size) throw new AppError('The question has no source text to translate.', 400);

    await fillTranslations(translations, sourceLang, targetLang);
    return Object.fromEntries(fields.map(([key, value]) => [key, Array.isArray(value)
        ? value.map(text => translations.get(text) ?? '') : translations.get(value)]));
}


async function fillTranslations(translations, sourceLang, targetLang) {
    // Share repeated strings across the form and bound the number of provider calls.
    const remaining = translations.keys();
    const stop = new AbortController();
    const deadline = AbortSignal.any([AbortSignal.timeout(30000), stop.signal]);
    async function worker() {
        for (const text of remaining) {
            translations.set(text, await translateText(text, sourceLang, targetLang, deadline));
        }
    }
    try {
        await Promise.all(Array.from({length: Math.min(4, translations.size)}, worker));
    } finally {
        stop.abort();
    }
}

async function batchTranslate(texts, sourceLang, targetLang) {
    if (!Array.isArray(texts)) throw new AppError('A list of translation texts is required.', 400);
    const translations = new Map();
    for (const text of texts) {
        if (text != null && typeof text !== 'string') throw new AppError('Invalid translation text.', 400);
        if (text?.trim()) translations.set(text, null);
    }
    await fillTranslations(translations, sourceLang, targetLang);
    return texts.map(text => translations.get(text) ?? null);
}

module.exports = {
    translateText,
    translateQuestion,
    batchTranslate
};
