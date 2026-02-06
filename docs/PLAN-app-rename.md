# PLAN: App Rename to ArborMed

Rename the entire project (Mobile, Backend, Docs, Folders) from "ArborMed" to "ArborMed".

## Overview
The goal is to transition the brand identity from ArborMed to ArborMed. This includes user-facing text, internal code identifiers, package names for app stores, and filesystem organization.

- **Project Type**: HYBRID (Flutter Mobile + Node.js Backend)
- **Task Slug**: `app-rename`

## Success Criteria
1. [ ] App builds and runs with new name "Arbor Med".
2. [ ] All internal "ArborMed" strings replaced (case-sensitive mapping).
3. [ ] Android Package Name updated to `com.example.arbormed`.
4. [ ] iOS Bundle Identifier updated to `com.example.arbormed`.
5. [ ] Filesystem reflects `arbor_med` naming.
6. [ ] Backend service identity updated.

## Tech Stack
- **Mobile**: Flutter/Dart
- **Backend**: Node.js/Express
- **Database**: PostgreSQL (Backend) + Drift/SQLite (Local)
- **Infrastructure**: Docker, Firebase

## File Structure Changes
- `mobile/lib/...` -> All files scanned for ArborMed.
- `mobile/android/app/src/main/kotlin/com/example/mobile` -> `.../com/example/arbormed`
- `backend/package.json` -> Updated name.
- Root folder `Med_buddy` -> `ArborMed`.

## Task Breakdown

### Phase 1: Global Search & Mapping
| Task ID | Name | Agent | Skill | Priority |
|---------|------|-------|-------|----------|
| 1.1 | Finalize casing maps | `orchestrator` | `brainstorming` | P0 |
| 1.2 | Scan for binary/asset references | `mobile-developer` | `mobile-design` | P1 |

### Phase 2: Core Code Rename
| Task ID | Name | Agent | Skill | Priority |
|---------|------|-------|-------|----------|
| 2.1 | Rename Flutter `pubspec.yaml` and title | `mobile-developer` | `clean-code` | P1 |
| 2.2 | Bulk string replacement in `lib/` | `mobile-developer` | `clean-code` | P1 |
| 2.3 | Rename backend `package.json` and strings | `backend-specialist` | `clean-code` | P1 |

### Phase 3: Platform Specifics (Android)
| Task ID | Name | Agent | Skill | Priority | Dependencies |
|---------|------|-------|-------|----------|--------------|
| 3.1 | Update `build.gradle` IDs | `mobile-developer` | `mobile-design` | P1 | - |
| 3.2 | Relocate Kotlin source files | `mobile-developer` | `mobile-design` | P2 | 3.1 |
| 3.3 | Update `AndroidManifest.xml` | `mobile-developer` | `mobile-design` | P1 | - |

### Phase 4: Platform Specifics (iOS)
| Task ID | Name | Agent | Skill | Priority |
|---------|------|-------|-------|----------|
| 4.1 | Update `Info.plist` and `project.pbxproj` | `mobile-developer` | `mobile-design` | P1 |

### Phase 5: Documentation & Filesystem
| Task ID | Name | Agent | Skill | Priority |
|---------|------|-------|-------|----------|
| 5.1 | Update `README.md` and `SETUP_INSTRUCTIONS.md` | `documentation-writer`| `clean-code` | P2 |
| 5.2 | Rename root directory | `orchestrator` | `clean-code` | P3 |

## Phase X: Verification
- [ ] Run `flutter pub get`
- [ ] Run `flutter analyze`
- [ ] Verify `google-services.json` package name manually.
- [ ] Build & Run check.
