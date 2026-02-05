# PLAN: Robust Inventory & Local-First Room Sync

This plan aims to resolve the "empty room" issue permanently by implementing a robust local-first synchronization strategy for shop items and user inventory.

## Status: IN ANALYSIS (Socratic Gate)

> [!IMPORTANT]
> This plan is currently in the discovery phase. Implementation will begin after resolving the questions below.

## Case for Improvement
The current system fails to display equipped items because the inventory sync (`fetchInventory`) does not persist item metadata (asset paths, names) to the local database, assuming they exist in the catalog. If the catalog hasn't been synced, the items become "invisible" to the renderer.

## Proposed Strategy (Conceptual)
1. **Unified Sync**: Treat inventory and catalog as a single transactional unit or ensure strict dependency.
2. **Metadata Persistence**: Ensure every `ShopUserItem` synced from the server validates and populates the local `Items` table.
3. **Resilient Rendering**: Implement fallback visuals for missing assets.
4. **Offline Capability**: Enable full room interaction without active server connection once initial sync is complete.

## Socratic Gate (User Review Required)
- **Local-First vs. Server-Dependent**: Should we prioritize full offline room functionality?
- **Metadata Bundling**: Should we bundle essential item data/assets with the app?
- **Fallback Strategy**: What should happen if an asset is missing or corrupted?

## Task Breakdown
*(To be populated after Phase 0)*
