💡 What: Pre-compute placed items into a Set instead of searching via `.any` inside the GridView.builder.
🎯 Why: The nested loop creates an O(N*M) bottleneck during scrolling which causes UI stutters.
📊 Impact: Reduces lookup complexity from O(N*M) to O(N+M) avoiding UI frame drops.
🔬 Measurement: Check performance overlay when scrolling in the shop catalog.
