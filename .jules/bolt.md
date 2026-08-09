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
## 2025-02-25 - Preventing O(N) linear scans on render loops
**Learning:** Performing multiple sequential array scans (`.any()` followed by `.firstWhere()`) inside a widget's build cycle (`_buildDetailActions` in `contextual_shop_sheet.dart`) causes a localized O(N) double-scan performance hit on every render frame. When dealing with lists of items (like a user's inventory), redundant iteration logic degrades rendering speed.
**Action:** Consolidate array scans into a single manual iteration pass (e.g., using a `for` loop) to evaluate conditions and extract the target element simultaneously, avoiding the double-scan overhead, and crucially, doing so without adding unnecessary external dependencies like `package:collection`.
## 2026-08-09 - Fixing ERR_PNPM_IGNORED_BUILDS in strict CI environments
**Learning:** PNPM v9+ prevents transitive build scripts from running automatically during `pnpm install`, causing `ERR_PNPM_IGNORED_BUILDS` (e.g. `unrs-resolver`) during strict Render deployments. Trying to update `.npmrc` is risky and can break global configs, and modifying workspace files may not persist safely depending on strict lockfile checks.
**Action:** Use `pnpm.approvedBuilds` (e.g., `{"unrs-resolver": "1.12.2"}`) explicitly in the root `package.json` to safely allowlist specific package build scripts. Always fully delete `node_modules` and regenerate `pnpm-lock.yaml` completely after to ensure PNPM acknowledges the allowlist configuration.
