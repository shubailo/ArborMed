
## 2024-03-01 - [Inventory Controller N+1 queries]
**Learning:** Found N+1 query loop in `syncRoomState` doing individual parameterized UPDATEs to Postgres.
**Action:** Replaced iterative UPDATE operations with a `bulk` UPDATE using `unnest` for efficient O(1) bulk data updates across multiple properties simultaneously.

## 2024-03-02 - [PostgreSQL Subquery Optimization]
**Learning:** Using `OR parent_id IN (SELECT id FROM topics WHERE slug = $1)` is inefficient. However, rewriting it as a `LEFT JOIN` with an `OR` condition spanning both tables defeats index usage and forces a sequential scan, making it an anti-optimization.
**Action:** Replaced the `IN` subquery pattern with a simpler uncorrelated subquery: `OR parent_id = (SELECT id FROM topics WHERE slug = $1)` when querying by `slug`, and dropped the subquery entirely when querying by `id` (`OR parent_id = $1`), which avoids full table scans and leverages index lookups directly.
