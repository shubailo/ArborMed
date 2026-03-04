// We need to implement a bulk insert and a bulk update.
// Bulk insert:
// INSERT INTO questions (question_text_en, question_text_hu, topic_id, bloom_level, difficulty, type, question_type, correct_answer, options, explanation_en, explanation_hu, created_by)
// VALUES ($1, $2, ...), ($11, $12, ...), ...

// Bulk update:
// UPDATE questions AS q
// SET question_text_en = c.question_text_en, ...
// FROM (VALUES ($1, $2, ...), ...) AS c(id, question_text_en, ...)
// WHERE q.id = c.id

// Another option for bulk update:
// UPDATE questions SET ... FROM (SELECT unnest($1::int[]) as id, unnest($2::text[]) as question_text_en, ...) as c WHERE questions.id = c.id

// Let's test how to do this in JS correctly.

const pgFormat = require('pg-format'); // wait, the memory said:
// "In services/backend, optimize bulk database insertions by using a single INSERT statement with a multi-row VALUES clause and parameter offsets (e.g., $1, $2, $3...) to avoid N+1 query overhead, particularly when external libraries like pg-format are unavailable."

// "To avoid N+1 query bottlenecks during database writes in PostgreSQL, use single bulk UPDATE operations leveraging the unnest function (e.g., UPDATE ... FROM (SELECT unnest($1::int[]) ...) rather than iterating with multiple parameterized queries."
