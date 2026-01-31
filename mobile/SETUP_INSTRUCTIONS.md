# Multi-Language Setup Instructions

## Quick Fix for Current Errors

The errors you're seeing are because the new packages haven't been installed yet. Follow these steps:

### 1. Install Flutter Packages

Open a terminal in the `mobile` folder and run:

```bash
flutter pub get
```

This will download:
- `flutter_localizations` (built-in Flutter SDK)
- `shared_preferences` (for saving language preference)

### 2. Generate Localization Files

After `flutter pub get` completes, Flutter will automatically generate the localization classes from your ARB files. If it doesn't, run:

```bash
flutter gen-l10n
```

This creates `lib/.dart_tool/flutter_gen/gen_l10n/app_localizations.dart`

### 3. Restart the App

```bash
flutter run -d chrome
# or
flutter run -d windows
```

---

## What to Expect

After these steps, you should see:

1. **Settings Sheet** → New "Language" option with EN/HU toggle
2. **Language Switch** → Click HU to switch to Hungarian (all UI labels change)
3. **Persistence** → Close and reopen app → Language preference is remembered

---

## Testing the Language Selector

1. Open app → Click Settings icon
2. Scroll to "Language" section
3. Click "HU" button
4. UI labels should change to Hungarian (e.g., "Settings" → "Beállítások")
5. Close app and reopen → Should still be in Hungarian

---

## Troubleshooting

### Error: "flutter: command not found"
- Make sure Flutter is installed and in your PATH
- Restart your terminal/IDE

### Error: "Failed to generate localizations"
- Check that `l10n.yaml` exists in the mobile folder
- Check that `lib/l10n/app_en.arb` and `lib/l10n/app_hu.arb` exist

### Error: "SharedPreferences not found"
- Run `flutter pub get` again
- Check `pubspec.yaml` has `shared_preferences: ^2.2.2`

---

## Next Steps (After Testing)

Once language switching works, we can implement:

1. **Admin Question Editor** - Add auto-translate button
2. **Quiz Display** - Show questions in selected language
3. **More Languages** - Add German, Arabic, etc.
