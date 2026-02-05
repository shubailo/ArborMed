# PLAN: Quiz Localization & Admin Enhancement

Implement full Hungarian support for the quiz menu, including static UI elements and dynamic content (quotes, topics). Improve the admin experience for multi-language management.

## Overview
This plan addresses the need for a fully localized user experience for Hungarian students while maintaining English fallbacks. It also upgrades the admin system to handle dual-language content with a better UI.

## Project Type: MOBILE + BACKEND

## Success Criteria
- [ ] Backend: `quotes` and `topics` tables support dual languages (`_en`, `_hu`).
- [ ] Admin: "Add Quote" dialog is larger, supports dual-language input, and shows a "Study Break" preview.
- [ ] Admin: "Topics" can be managed in both languages.
- [ ] Mobile: Quiz Menu static text respects the app's locale setting.
- [ ] Mobile: Dynamic content (topics, quotes) switches language based on locale.

## Tech Stack
- **Backend**: Node.js, Express, PostgreSQL (pg)
- **Mobile**: Flutter, Provider, GoogleFonts, arb (l10n)

## File Structure
- `backend/src/models/014_localize_quiz_entities.sql` (New Migration)
- `mobile/lib/l10n/app_en.arb` / `app_hu.arb` (Translations)
- `mobile/lib/widgets/admin/dual_language_field.dart` (Reuse/Enhance)
- `mobile/lib/widgets/admin/quote_preview_card.dart` (New Component)

## Task Breakdown

### Phase 1: Foundation (Backend)
| Task ID | Name | Agent | Skills | Priority |
|---------|------|-------|--------|----------|
| B1 | Schema Migration | `database-architect` | database-design | P0 |
| B2 | Controller Refactor | `backend-specialist` | api-patterns | P1 |
| B3 | Seed Fallback Script | `backend-specialist` | nodejs-best-practices | P1 |

**B1: Schema Migration**
- **INPUT**: Current `quotes` and `topics` table schemas.
- **OUTPUT**: `014_localize_quiz_entities.sql` adding `_hu` columns and standardizing `_en` suffixes.
- **VERIFY**: Run `migrate.js` or manual query check.

**B2: Controller Refactor**
- **INPUT**: `quizController.js`.
- **OUTPUT**: Updated logic for `getCurrentQuote`, `adminCreateQuote`, `getTopics`.
- **VERIFY**: API test with `Postman` or curl.

### Phase 2: Mobile Localization (L10n)
| Task ID | Name | Agent | Skills | Priority |
|---------|------|-------|--------|----------|
| M1 | Update ARB files | `mobile-developer` | i18n-localization | P0 |
| M2 | Update Models & StatsProvider | `mobile-developer` | clean-code | P1 |

**M1: Update ARB files**
- **INPUT**: `app_en.arb`, `app_hu.arb`.
- **OUTPUT**: Added keys for "Tanulás", "Start session", etc.
- **VERIFY**: Flutter l10n generate succeeds.

### Phase 3: Admin UI Overhaul
| Task ID | Name | Agent | Skills | Priority |
|---------|------|-------|--------|----------|
| A1 | Custom Add Quote Dialog | `mobile-developer` | mobile-design | P1 |
| A2 | Dual Language Topic Management | `mobile-developer` | mobile_design | P2 |

**A1: Custom Add Quote Dialog**
- **INPUT**: Target screenshot from user.
- **OUTPUT**: `AdminQuotesScreen` dialog with dual fields, preview widget, and balanced sizing.
- **VERIFY**: Click "Add Quote" in admin panel; visual check.

### Phase 4: Quiz Menu Refactor
| Task ID | Name | Agent | Skills | Priority |
|---------|------|-------|--------|----------|
| Q1 | Locale-aware QuizMenuWidget | `mobile-developer` | react-patterns | P1 |

**Q1: Locale-aware QuizMenuWidget**
- **INPUT**: `QuizMenuWidget`.
- **OUTPUT**: Replaced hardcoded strings with l10n calls; dynamic field selection for topics/quotes.
- **VERIFY**: Toggle app language in Settings; verify UI and content change.

## Phase X: Final Verification
- [ ] Run `npm run migrate` in backend.
- [ ] Verify `POST /api/quiz/admin/quotes` with dual text.
- [ ] Run `flutter gen-l10n`.
- [ ] Manual test: Verify Admin Dialog size and preview.
- [ ] Manual test: Verify Quiz Menu language toggle.

## ✅ PHASE X COMPLETE
- To be filled upon completion.
