# ArborMed Wireframes & Structural Layouts

This document outlines the proposed text-based wireframes and structural layouts to address the navigation and UI issues identified in the UI/UX audit.

## 1. Main Dashboard (Refactored Navigation)

**Current State:** Isometric room with floating icons that open full-screen modals.
**Proposed State:** Isometric room with a persistent Bottom Navigation Bar.

```text
+---------------------------------------------------+
|  [Currency: 120]                    [Streak: 5]   |
|                                                   |
|                                                   |
|                                                   |
|             (Isometric Room View)                 |
|            [Interactive Furniture]                |
|                                                   |
|                                                   |
|                                                   |
|                                                   |
|                                                   |
|                                                   |
|                                                   |
|              [START SESSION (Large Button)]       |
|                                                   |
|---------------------------------------------------|
|                      |             |              |
|      [Home]      [Study/Quiz]    [Shop]   [Profile]|
|     (Active)                                      |
+---------------------------------------------------+
```

**Changes:**
*   Added a 4-tab bottom navigation bar (`Home`, `Study/Quiz`, `Shop`, `Profile`).
*   Removed the floating gear icon (Settings moved to Profile).
*   Removed the floating badge icon (Profile moved to navigation bar).

---

## 2. Profile & Activity Screen (Unified)

**Current State:** Modal with two tabs ("Profile" and "Activity").
**Proposed State:** A dedicated, scrollable screen accessed via the Bottom Navigation Bar.

```text
+---------------------------------------------------+
|  < Back (If needed)               [Settings Gear] |
|                                                   |
|                (User Avatar)                      |
|                 Test Agent                        |
|              Medical ID: #024                     |
|                                                   |
|  +-------------------+  +-------------------+     |
|  |     STREAK        |  |         XP        |     |
|  |       5           |  |        1250       |     |
|  +-------------------+  +-------------------+     |
|                                                   |
|  ACTIVITY TREND (This Week)                       |
|  +---------------------------------------+        |
|  |  |                                    |        |
|  |  |      |                             |        |
|  |  |      |       |                     |        |
|  |  |______|_______|_______|_____________|        |
|  |   M   T   W   T   F   S   S           |        |
|  +---------------------------------------+        |
|                                                   |
|  RECENT QUESTS                                    |
|  - Complete 5 Cardiology questions [Claim]        |
|                                                   |
|---------------------------------------------------|
|                      |             |              |
|      [Home]      [Study/Quiz]    [Shop]   [Profile]|
|                                            (Active)|
+---------------------------------------------------+
```

**Changes:**
*   Eliminated the tab switcher between Profile and Activity.
*   Combined the User Info, Streak/XP stats, and the Activity Chart into a single scrollable view.
*   Moved the Settings gear to the top right of this screen.

---

## 3. "Night Shift" (Dark Mode Concept)

**Proposed State:** The application interface adapted for low-light environments.

```text
+---------------------------------------------------+
|  [Currency: 120]                    [Streak: 5]   |
|                                                   |
|                                                   |
|                                                   |
|          (Isometric Room View - NIGHT MODE)       |
|      Background: Deep Navy Blue (#0F172A)         |
|      Lighting: Warm yellow glow from desk lamp    |
|      UI Elements: Dark Grey (#1E293B) panels      |
|      Text: Soft Off-White (#F8FAFC)               |
|                                                   |
|                                                   |
|                                                   |
|                                                   |
|              [START SESSION (Large Button)]       |
|              (Button Color: Muted Sage Green)     |
|                                                   |
|---------------------------------------------------|
|                      |             |              |
|      [Home]      [Study/Quiz]    [Shop]   [Profile]|
|     (Active)                                      |
+---------------------------------------------------+
```

**Changes:**
*   Background colors shifted from off-white/cream to dark slate/navy.
*   The primary visual anchor (the isometric room) changes its lighting state to simulate a night-time study session.
*   Text colors inverted to maintain >4.5:1 contrast ratios in the dark theme.
