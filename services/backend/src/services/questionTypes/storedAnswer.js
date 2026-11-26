// Some seeders persist JSON in the historical TEXT correct_answer column.
function decodeStoredAnswer(value) {
  if (typeof value !== 'string') return value;
  const trimmed = value.trim();
  if (!['[', '{', '"'].includes(trimmed[0])) return value;
  try { return JSON.parse(trimmed); } catch { return value; }
}

function scalarAnswer(value) {
  const decoded = decodeStoredAnswer(value);
  const candidate = Array.isArray(decoded) && decoded.length === 1 ? decoded[0] : decoded;
  return ['string', 'number', 'boolean'].includes(typeof candidate) ? candidate : null;
}

module.exports = { decodeStoredAnswer, scalarAnswer };
