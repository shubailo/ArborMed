---
description: How to add new furniture items to the shop and room
---

# Adding New Furniture & Assets Workflow

Follow these steps to add a new inventory item (desk, chair, rug, or room) to the game using the automation pipeline.

## 1. Asset Preparation

1.  **Place the Asset**:
    *   **Furniture**: Put `.webp` images in `mobile/assets/images/furniture/`.
    *   **Rooms**: Put `.webp` images in `mobile/assets/images/room/`.
    *   Naming convention: `snake_case` (e.g., `modern_desk.webp`, `zen_garden.webp`).

2.  **Process the Image (Resizing & Clipping)**:
    *   Run the optimization script to resize (max 800px) and apply hard alpha clipping.
    *   **Command**:
        ```bash
        python tools/hard_alpha_clip.py
        ```
    *   **CRITICAL**: You MUST wait for this to finish before generating metadata or hitboxes.

## 2. Generate Technical Data

1.  **Generate Image Metadata**:
    *   Updates `mobile/lib/widgets/cozy/image_meta.dart` with dimensions.
    *   **Command**:
        ```bash
        python tools/generate_image_meta.py
        ```

2.  **Generate Hitboxes (Voxels)**:
    *   Analyzes the image and generates pixel-perfect click-zones in `mobile/lib/widgets/cozy/voxel_data.dart`.
    *   **Command**:
        ```bash
        python tools/generate_voxel_hitboxes.py
        ```

## 3. Register in Automation Manifest

1.  **Update Manifest**:
    *   Open `mobile/assets/shop_manifest.json`.
    *   Add a new entry to the `items` list:
        ```json
        {
          "id": "item_slug",
          "numeric_id": 900, 
          "name": "Display Name",
          "price": 150,
          "slot_type": "desk"
        }
        ```
    *   *Note*: `numeric_id` must be unique. `slot_type` must match an existing slot in the app.

## 4. Run Synchronization Pipeline

1.  **Generate Code & SQL**:
    *   Run the maintenance script to update the Flutter catalog and generate the database migration.
    *   **Command**:
        ```bash
        python tools/maintain_shop.py
        ```
    *   *Result*: Updates `mobile/lib/models/generated_shop_catalog.dart` and creates a `.sql` file in `backend/migrations/`.

2.  **Apply Database Sync**:
    *   Locate the latest generated migration (e.g., `sync_shop_YYYYMMDD.sql`).
    *   Apply it to the Supabase database.
    *   **Command**:
        ```bash
        node backend/apply_migration.js sync_shop_YYYYMMDD.sql
        ```

## 5. Verify & Restart

1.  **Flutter Hot Restart**:
    *   Save all files and perform a **Hot Restart** in your Flutter debug session.
2.  **Verify Presence**:
    *   Open the shop and verify the new item appears with the correct price and icon.
3.  **Verify Placement**:
    *   Equip the item and verify it renders at the correct isometric coordinates in the room.