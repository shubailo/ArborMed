// PostgreSQL stores question and session identifiers as positive int4 values.
function positiveId(value) {
  if (typeof value !== 'number' && (typeof value !== 'string' || !/^\d+$/.test(value.trim()))) return null;
  const id = Number(value);
  return Number.isInteger(id) && id > 0 && id <= 2147483647 ? id : null;
}

module.exports = { positiveId };
