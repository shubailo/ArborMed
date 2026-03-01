
## 2024-03-01 - [Inventory Controller N+1 queries]
**Learning:** Found N+1 query loop in `syncRoomState` doing individual parameterized UPDATEs to Postgres.
**Action:** Replaced iterative UPDATE operations with a `bulk` UPDATE using `unnest` for efficient O(1) bulk data updates across multiple properties simultaneously.
