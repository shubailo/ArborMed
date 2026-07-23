## 2024-01-01 - [Pre-existing file test]
**Learning:** test
**Action:** test
## 2024-07-23 - [O(1) Precomputation in Flutter Builders]
**Learning:** Running `.any()` or `.firstWhere()` on providers inside Flutter `GridView.builder` or `ListView.builder` callbacks causes severe O(N*M) performance degradation during scrolling, as it repeats the scan on every render cycle.
**Action:** Always extract the context lookup and precompute derived provider state (like a `Set` or `Map`) into O(1) data structures outside the builder loop before passing them down to individual list/grid item widgets.
