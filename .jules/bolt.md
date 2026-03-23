## 2026-03-23 - Optimize Drift local sync
**Learning:** O(N*M) local collection scans within a loop significantly degrade performance during bulk syncs, and Drift's batch.insert within loops adds overhead.
**Action:** Replaced O(N*M) scans with O(1) Map lookups for matching local to remote items and swapped loop-based batch.insert with batch.insertAll for bulk database operations.
## 2026-03-23 - Optimize Drift local sync
**Learning:** O(N*M) local collection scans within a loop significantly degrade performance during bulk syncs, and Drift's batch.insert within loops adds overhead.
**Action:** Replaced O(N*M) scans with O(1) Map lookups for matching local to remote items and swapped loop-based batch.insert with batch.insertAll for bulk database operations.
