
## 2024-03-01 - [Inventory Controller N+1 queries]
**Learning:** Found N+1 query loop in `syncRoomState` doing individual parameterized UPDATEs to Postgres.
**Action:** Replaced iterative UPDATE operations with a `bulk` UPDATE using `unnest` for efficient O(1) bulk data updates across multiple properties simultaneously.

## 2024-03-02 - [PostgreSQL Subquery Optimization]
**Learning:** Using `OR parent_id IN (SELECT id FROM topics WHERE slug = $1)` is inefficient. However, rewriting it as a `LEFT JOIN` with an `OR` condition spanning both tables defeats index usage and forces a sequential scan, making it an anti-optimization.
**Action:** Replaced the `IN` subquery pattern with a simpler uncorrelated subquery: `OR parent_id = (SELECT id FROM topics WHERE slug = $1)` when querying by `slug`, and dropped the subquery entirely when querying by `id` (`OR parent_id = $1`), which avoids full table scans and leverages index lookups directly.

## 2025-03-03 - [PostgreSQL EXISTS vs IN Materialization Optimization]
**Learning:** In queries performing heavy aggregation or joining large subsets (like `getQuestionStats` or `getActivity`), using the `IN (SELECT id FROM ...)` anti-pattern forces PostgreSQL to materialize a list or perform less efficient hash/merge scans, rather than using indexed lookups for filtering (e.g., `WHERE user_id NOT IN (SELECT id FROM users ...)`).
**Action:** Replaced standard uncorrelated `IN` and `NOT IN` subquery clauses with `EXISTS` and `NOT EXISTS` (e.g., `WHERE EXISTS (SELECT 1 FROM quiz_sessions qs WHERE qs.id = r.session_id AND qs.user_id = $1)`). This enables the query planner to utilize primary key / foreign key indexes directly for row verification and terminates scanning as soon as a match is found, particularly critical for high-volume historical tracking tables like `responses` and `quiz_sessions`.

## 2025-05-14 - [Gold Catalog Seeding N+1 Query Optimization]
**Learning:** The `seedGoldCatalog.js` script used a loop to perform individual `INSERT` queries for each item, causing N+1 query overhead.
**Action:** Refactored the insertion logic to use a single multi-row `VALUES` batch `INSERT` statement, reducing database roundtrips from 12 to 1 for the items list. Verified the reduction using a mock-based benchmark script.

## 2024-05-20 - Redundant Object.values Traversal
**Learning:** `Object.values()` creates a new array each time it's called. Calling it multiple times on the same object within a loop or `map` callback creates unnecessary memory allocations and redundant iterations, degrading performance.
**Action:** When iterating over or accessing the values of an object multiple times, cache the result of `Object.values()` in a variable and reuse it.

## 2025-03-04 - Batch Processing N+1 Queries in Excel Uploads
**Learning:** During large Excel batch uploads, iterating rows and performing individual `INSERT` and `UPDATE` queries creates an N+1 query pattern, increasing overhead linearly with the number of rows.
**Action:** Replaced the row loop with two arrays, separating rows into `insertsToProcess` and `updatesToProcess`. Implemented bulk `INSERT INTO ... VALUES` using sequential `$x` parameters, and bulk `UPDATE ... FROM (SELECT unnest(...) ...)` using array parameters, all processed safely in chunks of 500 rows to prevent breaking PostgreSQL parameter limits. Queries went from O(N) to roughly O(N/500), showing huge benchmark improvements.

## 2025-03-05 - [Express CORS Parsing Overhead]
**Learning:** Checking `origin` against `process.env.ALLOWED_ORIGINS` inside the `cors` middleware's `origin` function executes on every incoming request. Parsing `ALLOWED_ORIGINS.split(',')` inside this function re-calculates the array each time. For a high-throughput endpoint, this causes continuous small memory allocations and GC overhead.
**Action:** When configuring Express middleware functions that execute per-request, hoist any static parsing (like `.split(',')` on environment variables) outside the middleware callback. Calculate the array once during server startup and use `.includes()` on the cached array in the callback.

## 2024-03-08 - [Optimize validateBilingual Array Lookups]
**Learning:** Found O(N^2) complexity in `validateBilingual` due to nested array `.includes()` calls within `.every()` and `.some()` loops when comparing user answers to database options.
**Action:** Replaced arrays with `Set` objects for O(1) lookups before iteration, improving validation speed, especially for questions with longer text options or larger option sets.
