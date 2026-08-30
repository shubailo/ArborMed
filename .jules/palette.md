## 2024-05-18 - Avoid generating missing localization files directly

**Learning:** When adding localization strings to a Flutter project with `flutter gen-l10n`, the strings must be present in the original `.arb` source files. Calling localized strings from `.dart` source code before updating the corresponding `.arb` file will cause a `gen-l10n` build failure if it tries to find a string that was not added to the translations first.

**Action:** Ensure both English and Hungarian `.arb` translation files are successfully updated and confirmed before running `flutter gen-l10n` or executing tests for widgets that depend on localization generation.
