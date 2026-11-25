function splitPair(value) {
  if (typeof value !== 'string') return null;
  const separator = /\s+(?:->|→)\s+/.test(value) ? /\s+(?:->|→)\s+/ : /:\s+/;
  const terms = value.split(separator).map(part => part.trim());
  return terms.length === 2 && terms.every(Boolean) ? terms : null;
}

module.exports = splitPair;
