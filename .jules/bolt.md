## 2025-02-23 - CTE Pre-aggregation vs Direct LEFT JOIN Performance
**Learning:** Performing a direct `LEFT JOIN` from a core table (e.g. `users`) to deep multiple one-to-many relationship tables (`quiz_sessions` -> `responses` -> `questions` -> `topics`) and performing a global `GROUP BY u.id` causes a massive cross-product explosion of rows evaluated in memory by the database before aggregation. In `services/backend/src/controllers/statsController.js`, this pattern took ~850ms.
**Action:** Use Common Table Expressions (CTEs) to filter and pre-aggregate the related deep data into a flat temporary set (`AggregatedStats`), and then `LEFT JOIN` this already grouped data to the primary table. This reduced execution time to ~115ms (a ~7x improvement) by minimizing the row operations the DB engine has to compute. Always pre-aggregate related data when generating complex stats.

## 2024-03-10 - Optimizing User Topic Progress Stats
**Learning:** Joining large tables like `responses` with aggregate data in main queries (like `user_topic_progress`) can lead to an O(N*M) row explosion when grouping by topics, especially due to missing specific index optimizations and multiple `LEFT JOIN` aggregations. This causes postgres to multiply the output rows internally, significantly dragging down performance.
**Action:** Always pre-aggregate user interaction stats (like `response_time_ms`) via a `Common Table Expression (CTE)` *before* doing `LEFT JOIN` operations against user progress summary tables.

## 2025-02-24 - Pre-aggregating with CTEs to Prevent Join Explosion
**Learning:** Joining multiple 1-to-many relationship tables (`topics` -> `questions` -> `responses`) directly and grouping at the very end causes an O(N*M) row explosion in PostgreSQL's memory, drastically slowing down the query. Merely using a CTE to select columns is insufficient; the CTE itself must perform the aggregation (e.g., `GROUP BY question_id`) before the results are joined to the larger tree structure.
**Action:** Always fully pre-aggregate 1-to-many deep data using a Common Table Expression (CTE) *before* performing a `LEFT JOIN` against large primary tables or hierarchical trees like topics. Ensure the `GROUP BY` happens inside the CTE.

## 2025-03-16 - Pre-aggregating Before JOINing for Analytics Queries
**Learning:** Even simple analytics queries (like calculating success rates for topics) can suffer performance degradation if large log tables (like `responses`) are joined directly to reference tables (`questions`, `topics`) before grouping. Grouping over the joined output causes PostgreSQL to process exponentially more data in memory.
**Action:** Always use CTEs to pre-aggregate high-volume log data (e.g., `COUNT`, `SUM` grouped by foreign key) *before* joining the aggregated results to smaller reference tables.

## 2025-10-24 - Pre-building Map for O(1) Lookups Inside Loops
**Learning:** Using `firstWhere` inside an iterative mapping loop (like hydrating domain objects from a database result) causes an O(N*M) time complexity, dragging down performance as the catalog and inventory sizes grow.
**Action:** Pre-build a Map keyed by the target ID (e.g., `Map<String, FurnitureItem>`) before the loop. This reduces the complexity to O(N+M) allowing O(1) lookups during hydration.
