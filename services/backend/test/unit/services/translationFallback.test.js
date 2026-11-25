jest.mock('google-translate-api-x', () => jest.fn());
jest.mock('../../../src/utils/logger', () => ({info: jest.fn(), debug: jest.fn(), error: jest.fn()}));

const originalFetch = global.fetch;

function service(provider) {
  jest.replaceProperty(process, 'env', {
    ...process.env, TRANSLATION_PROVIDER: provider, LIBRETRANSLATE_URL: 'http://translation.test',
  });
  return require('../../../src/services/translationService');
}

beforeEach(() => {
  jest.resetModules();
  global.fetch = jest.fn();
});

afterEach(() => {
  global.fetch = originalFetch;
  jest.restoreAllMocks();
});

test('falls back from Google to Libre using the original text and language pair', async () => {
  const {translateText} = service('GOOGLE');
  const google = require('google-translate-api-x');
  google.mockRejectedValue(new Error('primary unavailable'));
  global.fetch.mockResolvedValue({ok: true, json: async () => ({translatedText: 'kék'})});
  await expect(translateText('blue', 'en', 'hu')).resolves.toBe('kék');
  expect(google).toHaveBeenCalledWith('blue', {from: 'en', to: 'hu', forceBatch: false});
  expect(global.fetch).toHaveBeenCalledWith('http://translation.test/translate', {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({q: 'blue', source: 'en', target: 'hu', format: 'text'}),
  });
});

test('retries a Libre HTTP failure with Google and bypasses transport for empty or same-language text', async () => {
  const {translateText} = service('LIBRE');
  const google = require('google-translate-api-x');
  global.fetch.mockResolvedValue({ok: false, status: 503, statusText: 'Unavailable'});
  google.mockResolvedValue({text: 'blue'});
  await expect(translateText('  ', 'hu', 'en')).resolves.toBeNull();
  await expect(translateText('kék', 'hu', 'hu')).resolves.toBe('kék');
  await expect(translateText('kék', 'hu', 'en')).resolves.toBe('blue');
  expect(global.fetch).toHaveBeenCalledTimes(1);
  expect(google).toHaveBeenCalledTimes(1);
});

test('translates all supported question fields and retains their order', async () => {
  const {translateQuestion, batchTranslate} = service('GOOGLE');
  require('google-translate-api-x').mockImplementation(async text => ({text: 'hu-' + text}));
  const question = {
    questionText: 'Q', options: ['first','second'], explanation: 'why',
    statement1: 'one', statement2: 'two', link_word: 'because',
    lefts: ['A','B'], rights: ['X','Y'], correct_answer: 'A',
  };
  await expect(translateQuestion(question, 'en', 'hu')).resolves.toEqual({
    questionText: 'hu-Q', options: ['hu-first','hu-second'], explanation: 'hu-why',
    statement1: 'hu-one', statement2: 'hu-two', link_word: 'hu-because',
    lefts: ['hu-A','hu-B'], rights: ['hu-X','hu-Y'],
  });
  await expect(batchTranslate(['A','B'], 'en', 'hu')).resolves.toEqual(['hu-A','hu-B']);
  expect(question.options).toEqual(['first','second']);
  expect(global.fetch).not.toHaveBeenCalled();
});

test('a double provider failure rejects a question and labels every untranslated batch item', async () => {
  const {translateQuestion, batchTranslate} = service('LIBRE');
  global.fetch.mockRejectedValue(new Error('unreachable'));
  const fallbackError = new Error('translation service unavailable');
  require('google-translate-api-x').mockRejectedValue(fallbackError);
  await expect(translateQuestion({questionText: 'Q'}, 'hu', 'en')).rejects.toBe(fallbackError);
  await expect(batchTranslate(['kék', 'zöld'], 'hu', 'en')).resolves.toEqual(['[EN] kék', '[EN] zöld']);
});
