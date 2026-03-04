## 2024-03-04 - Strict Pagination Limits
**Vulnerability:** Missing upper bounds on pagination `limit` parameters allowed potentially massive database queries, presenting a Denial of Service (DoS) risk.
**Learning:** Default destructuring assignments (e.g., `const { limit = 100 } = req.query`) only cover `undefined` values and do not prevent attackers from supplying excessively large limits like `9999999` or non-integer values.
**Prevention:** Always parse `limit` parameters as base-10 integers (`parseInt(val, 10)`), provide a safe fallback for invalid input (`|| default`), and strictly enforce both lower bounds (e.g., `< 1`) and upper caps (e.g., `> 1000`).
