
## 2024-03-01 - [Inventory Controller N+1 queries]
**Learning:** Found N+1 query loop in `syncRoomState` doing individual parameterized UPDATEs to Postgres.
**Action:** Replaced iterative UPDATE operations with a `bulk` UPDATE using `unnest` for efficient O(1) bulk data updates across multiple properties simultaneously.

## 2024-03-02 - [PostgreSQL Subquery Optimization]
**Learning:** Using `OR parent_id IN (SELECT id FROM topics WHERE slug = $1)` is inefficient. However, rewriting it as a `LEFT JOIN` with an `OR` condition spanning both tables defeats index usage and forces a sequential scan, making it an anti-optimization.
**Action:** Replaced the `IN` subquery pattern with a simpler uncorrelated subquery: `OR parent_id = (SELECT id FROM topics WHERE slug = $1)` when querying by `slug`, and dropped the subquery entirely when querying by `id` (`OR parent_id = $1`), which avoids full table scans and leverages index lookups directly.

## 2025-03-03 - [PostgreSQL EXISTS vs IN Materialization Optimization]
**Learning:** In queries performing heavy aggregation or joining large subsets (like `getQuestionStats` or `getActivity`), using the `IN (SELECT id FROM ...)` anti-pattern forces PostgreSQL to materialize a list or perform less efficient hash/merge scans, rather than using indexed lookups for filtering (e.g., `WHERE user_id NOT IN (SELECT id FROM users ...)`).
**Action:** Replaced standard uncorrelated `IN` and `NOT IN` subquery clauses with `EXISTS` and `NOT EXISTS` (e.g., `WHERE EXISTS (SELECT 1 FROM quiz_sessions qs WHERE qs.id = r.session_id AND qs.user_id = $1)`). This enables the query planner to utilize primary key / foreign key indexes directly for row verification and terminates scanning as soon as a match is found, particularly critical for high-volume historical tracking tables like `responses` and `quiz_sessions`.
