# PLAN-theme-refactor

> **Objective**: Refactor the existing static `CozyTheme` into a dynamic "Palette Pattern" system to support Dark Mode (Midnight Cocoa) and future scalability.

## 1. Context & Architecture

### The Problem
Currently, `CozyTheme` uses `static const` fields (e.g., `CozyTheme.primary`). This makes runtime theme switching impossible without a full app restart and prevents having multiple active color schemes.

### The Solution: "Palette Pattern"
We will separate **Design Tokens** (Colors, Gradients) from **Theme Logic** (TextStyles, ButtonShapes).

- **`CozyPalette` (Interface)**: The contract defining all required colors.
- **`CozyLogic` (The "Huge" File)**: The single source of truth for shapes, typography, and spacing. It accepts a `CozyPalette` and generates a Flutter `ThemeData`.
- **`CozyProvider`**: A simplified `InheritedWidget` to allow `context.cozy.primary` access (retaining the ease of use).

---

## 2. Implementation Steps

### Phase 1: The Foundation (New Files)
Create the new structure without breaking the old one yet.

- [ ] **Create Directory**: `lib/theme/palettes/`
- [ ] **Create Interface**: `lib/theme/cozy_palette.dart`
    - Abstract class defining getters for all colors (background, primary, surface, etc.).
- [ ] **Create Implementations**:
    - `lib/theme/palettes/light_palette.dart` (Moving current colors here).
    - `lib/theme/palettes/dark_palette.dart` (New "Midnight Cocoa" scheme).

### Phase 2: The Engine (Refactor `CozyTheme`)
Transform `CozyTheme` from a static class to a dynamic Provider.

- [ ] **State Management**:
    - Create `ThemeService` (extends ChangeNotifier) to hold the current `CozyPalette`.
    - Implement `toggleTheme()` and persistence (using `shared_preferences`).
- [ ] **Refactor `CozyTheme` Class**:
    - Add `static ThemeData create(CozyPalette palette)` factory.
    - Add `static CozyPalette of(BuildContext context)` helper.

### Phase 3: The Integration
Connect the new engine to the app root.

- [ ] **Update `main.dart`**:
    - Initialize `ThemeService`.
    - Wrap `MaterialApp` in `ChangeNotifierProvider<ThemeService>`.
    - Bind `MaterialApp.theme` to the dynamic `ThemeData`.

### Phase 4: The Great Migration (Refactor 40+ Files)
Replace static calls with context-aware calls.

- [ ] **Find & Replace**:
    - `CozyTheme.primary` -> `CozyTheme.of(context).primary`
    - `CozyTheme.textTheme` -> `Theme.of(context).textTheme`
- [ ] **Verify Components**:
    - Check complex widgets like `CozyButton`, `CozyProgressBar`, and `StatusPill` for proper context usage.

---

## 3. Verification Plan

### Automated Checks
- [ ] Run `flutter analyze` to ensure no `static` properties are being accessed incorrectly.
- [ ] Run `flutter test` to verify the provider injects correctly.

### Manual Review (UI Audit)
1.  **Light Mode**: Verify it looks *exactly* 100% identical to the current app.
2.  **Dark Mode**:
    - **Dashboard**: Check background contrast.
    - **Quiz Screen**: Ensure white cards don't blind the user (should be dark grey/espresso).
    - **Text**: Ensure dark text turns light cream.
3.  **Toggle Test**: Switch themes mid-session and verify immediate update without restart.

---

## 4. "Midnight Cocoa" Palette Spec 🌑

| Token | Light (Current) | Dark (New) |
| :--- | :--- | :--- |
| **Background** | Ivory (`#FDFCF8`) | Espresso (`#2C241B`) |
| **Surface** | White (`#FFFFFF`) | Dark Roast (`#3E342B`) |
| **Primary** | Sage (`#8CAA8C`) | Moonlit Sage (`#A3CFA3`) |
| **Text Primary** | Deep Brown (`#4A3728`) | Cream (`#FDFCF8`) |
| **Text Secondary** | Medium Brown (`#8D6E63`) | Latte (`#D7CCC8`) |

---

## 5. Next Steps

Run the following command to begin Phase 1:
`/create` - I will start by creating the palette directory and files.
