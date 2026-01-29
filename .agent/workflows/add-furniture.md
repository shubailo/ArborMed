---
description: How to add new furniture items to the shop and room
---

# Adding New Furniture Workflow

Follow these steps to add a new furniture item (desk, chair, wall decor, etc.) to the game.

## 1. Asset Preparation

1.  **Place the Asset**:
    *   Put your source image (PNG/WEBP) in `mobile/assets/images/furniture/`.
    *   Naming convention: `snake_case` (e.g., `wall_decor.webp`, `modern_desk.webp`).

2.  **Process the Image**:
    *   Run the optimization script to resize (max 800px) and apply hard alpha clipping (ghosting prevention).
    *   **Command**:
        ```bash
        python hard_alpha_clip.py
        ```
    *   *Note*: This script processes the `mobile/assets/images/furniture/` directory by default.
    *   **CRITICAL**: You MUST wait for this script to finish resizing images (from 2048px -> 800px) before running the next step.

3.  **Generate Image Metadata**:
    *   Run the script to generate size metadata for proper icon zooming in the shop.
    *   **Command**:
        ```bash
        python generate_image_meta.py
        ```
    *   *Verify*: Check `mobile/lib/widgets/cozy/image_meta.dart` to ensure your new file is listed with correct size (e.g., 800x800).

## 2. Generate Hitboxes (Voxels)

1.  **Generate Voxels**:
    *   Run the script to analyze the image and generate pixel-perfect hitboxes for interaction.
    *   **Command**:
        ```bash
        python generate_voxel_hitboxes.py
        ```
    *   *Verify*: Check `mobile/lib/widgets/cozy/voxel_data.dart` to ensure your new file is listed.
    *   **Importance**: If you run this *before* resizing/clipping, the hitboxes will be calculated on the huge original image and will be unusable (off-screen) in the app. Always run `hard_alpha_clip.py` first!

## 3. Register in Shop Catalog

1.  **Edit `shop_provider.dart`**:
    *   File: `mobile/lib/services/shop_provider.dart`
    *   Find `class ShopCatalog`.
    *   Add a new `ShopItem` entry:
        ```dart
        ShopItem(
          id: 501, // Unique ID
          name: 'My New Item',
          type: 'furniture',
          slotType: 'wall_decor', // or 'furniture', 'floor_decor'
          price: 500,
          assetPath: 'assets/images/furniture/my_new_item.webp',
          description: 'Description here.',
          isOwned: false,
        ),
        ```

## 4. Configure Layering (Z-Index)

1.  **Update `zIndex` Logic**:
    *   File: `mobile/lib/services/shop_provider.dart`
    *   Check `ShopItem.zIndex` and `UserItem.zIndex` getters.
    *   Ensure your `slotType` has a correct Z-index (e.g., `wall_decor` should be `15` to sit behind furniture but in front of wall).
        ```dart
        case 'wall_decor': return 15;
        ```

## 5. Enable Ghost/Blueprint (Optional)

1.  **Add Slot Definition**:
    *   If this is a *new* location or slot type, add it to `_availableSlots` in `shop_provider.dart`.
    *   File: `mobile/lib/services/shop_provider.dart`
    *   Find `_availableSlots`:
        ```dart
        {'slot': 'wall_decor', 'x': 0, 'y': 2, 'name': 'Wall Decoration'},
        ```
    *   *Note*: The `x` and `y` are isometric grid coordinates.

## 6. Verify

1.  **Run the App**:
    *   Enter **Decorate Mode**.
    *   Check if the **Ghost** (blueprint) appears at the correct location.
    *   **Equip** the item from the shop.
    *   **Tap** the item to ensure the hitbox works (it should bounce/animate).
