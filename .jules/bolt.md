## 2025-02-23 - CTE Pre-aggregation vs Direct LEFT JOIN Performance
**Learning:** Performing a direct `LEFT JOIN` from a core table (e.g. `users`) to deep multiple one-to-many relationship tables (`quiz_sessions` -> `responses` -> `questions` -> `topics`) and performing a global `GROUP BY u.id` causes a massive cross-product explosion of rows evaluated in memory by the database before aggregation. In `services/backend/src/controllers/statsController.js`, this pattern took ~850ms.
**Action:** Use Common Table Expressions (CTEs) to filter and pre-aggregate the related deep data into a flat temporary set (`AggregatedStats`), and then `LEFT JOIN` this already grouped data to the primary table. This reduced execution time to ~115ms (a ~7x improvement) by minimizing the row operations the DB engine has to compute. Always pre-aggregate related data when generating complex stats.

## 2024-03-10 - Optimizing User Topic Progress Stats
**Learning:** Joining large tables like `responses` with aggregate data in main queries (like `user_topic_progress`) can lead to an O(N*M) row explosion when grouping by topics, especially due to missing specific index optimizations and multiple `LEFT JOIN` aggregations. This causes postgres to multiply the output rows internally, significantly dragging down performance.
**Action:** Always pre-aggregate user interaction stats (like `response_time_ms`) via a `Common Table Expression (CTE)` *before* doing `LEFT JOIN` operations against user progress summary tables.

## 2025-02-24 - Pre-aggregating with CTEs to Prevent Join Explosion
**Learning:** Joining multiple 1-to-many relationship tables (`topics` -> `questions` -> `responses`) directly and grouping at the very end causes an O(N*M) row explosion in PostgreSQL's memory, drastically slowing down the query. Merely using a CTE to select columns is insufficient; the CTE itself must perform the aggregation (e.g., `GROUP BY question_id`) before the results are joined to the larger tree structure.
**Action:** Always fully pre-aggregate 1-to-many deep data using a Common Table Expression (CTE) *before* performing a `LEFT JOIN` against large primary tables or hierarchical trees like topics. Ensure the `GROUP BY` happens inside the CTE.

## 2025-02-24 - Pre-building Hash Maps to prevent O(N*M) local data synchronization linear scans
**Learning:** Using `.where(...).firstOrNull` on a list of local database items inside a loop that iterates over remote inventory responses creates an O(N*M) time complexity bottleneck.
**Action:** Always pre-process the local items list into `Map<key, List<Item>>` for O(1) lookups before the loop, and use `removeLast()` to consume the matched items safely without introducing O(N) array shifting.

## 2026-04-24 - Pre-building Hash Maps for O(N*M) loop elimination
**Learning:** Using `.firstWhere` or `.any` on a list of local database items inside a `.map` loop that iterates over a catalog creates an O(N*M) time complexity bottleneck. In `shop_provider.dart`, scanning `localInventory` for each item in `_catalog` causes severe performance degradation as the catalog and user inventory grow.
**Action:** Always pre-process lists into Hash Maps (e.g., `Map<int, int>`) for O(1) lookups *before* iterating over large lists, ensuring array scans inside loops are eliminated.
## 2025-02-18 - Prevent O(N) UI Stutter with Derived Caches
**Learning:** In Flutter, performing O(N) linear scans (e.g., using `list.any()` or `list.firstWhere()`) directly inside `build` methods, particularly within list builders, causes significant UI stutter. We must also verify that derived caches are properly invalidated or rebuilt across all state mutation methods.
**Action:** Pre-compute these properties into O(1) structures like `Set` or `Map` in the state provider. Synchronize caches with base state updates and comment the synchronization mechanism clearly.
