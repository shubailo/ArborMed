# Shop Automation Pipeline (Asset-First Architecture)

## 1. Goal
Eliminate manual shop maintenance and synchronization bugs by treating **System Assets + Manifest** as the single source of truth.

## 2. Architecture

### Source of Truth
*   **Assets:** `mobile/assets/images/furniture/*.webp` (The visual reality)
*   **Metadata:** `mobile/assets/shop_manifest.yaml` (The business logic)

### Automation Script (`tools/maintain_shop.py`)
A Python script that runs on demand (and CI/CD) to:
1.  **Scan** `assets/` and `manifest.yaml`.
2.  **Validate** integrity (Image exists? Price set?).
3.  **Generate** `lib/models/generated_shop_catalog.dart` (Hardcoded Flutter speed).
4.  **Generate** `backend/migrations/sync_shop_items.sql` (DB sync).

## 3. Work Streams

### Phase 1: Foundation (The Tools)
- [ ] Create `mobile/assets/shop_manifest.yaml` prototype.
- [ ] Create `tools/maintain_shop.py` skeleton.
- [ ] Implement **Asset Scanner** (File I/O).
- [ ] Implement **Manifest Parser** (YAML).

### Phase 2: Generation (The Code)
- [ ] Implement **Dart Generator**:
    - Template for `ShopCatalog.dart`.
- [ ] Implement **SQL Generator**:
    - UPSERT logic (Update if exists, Insert if new).

### Phase 3: Migration (The Switch)
- [ ] Switch `ShopProvider.dart` to use `GeneratedShopCatalog`.
- [ ] Run initial SQL migration on Supabase.
