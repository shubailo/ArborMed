# PLAN-personalized-analytics.md

## Overview
Recreate the `Wardrobe` feature as a **Personalized Analytics & Mastery Dashboard**. This plan transforms the static wardrobe into a dynamic portal where users can track their learning progress, question activity, and mastery across different Bloom's Taxonomy levels.

**Key Features:**
- **Activity Tracking**: Bar charts showing daily question volume (Day/Week/Month/Year).
- **Mastery Overview**: High-level proficiency in major subjects (Cardiology, etc.).
- **Specific Section Mastery**: Hexagonal (Radar) charts for sub-system proficiency.
- **Bloom-based Mastery**: Proficiency increases as the user masters higher Bloom levels.
- **Navigation**: "Quiz-Menu-style" zoom transitions between dashboard layers.

---

## Project Type
- **MOBILE** (Flutter)
- **BACKEND** (Node.js/SQL)

---

## Success Criteria
- [ ] Backend API provides aggregated stats (answered counts, correct ratios, Bloom progress).
- [ ] Main Dashboard displays Activity Bar Chart (Question count over time).
- [ ] Subject Tiles show "Overall Mastery" percentage.
- [ ] Clicking a Subject Card "Zooms" into a detailed view with a **Hexagonal (Radar) Chart**.
- [ ] Radar Chart correctly visualizes proficiency across 6 sections (Bloom levels or sub-topics).
- [ ] Navigation matches the Quiz Menu's premium layout and "Folder-style" transitions.
- [ ] Wardrobe exists as a secondary tab (Coming Soon) to maintain the 2-button bottom nav.

---

## Tech Stack
- **Frontend**: Flutter
- **Charts**: `fl_chart` (BarChart, RadarChart)
- **Backend**: Express (Node.js) + SQL (PostgreSQL/PostGIS)
- **Animations**: `AnimatedSwitcher` + `ScaleTransition` (Zoom effect)

---

## File Structure

### [NEW]
- `backend/src/controllers/statsController.js`: Logical aggregation of user performance.
- `backend/src/routes/statsRoutes.js`: Endpoints for analytics.
- `mobile/lib/widgets/analytics/analytics_dashboard.dart`: Main container.
- `mobile/lib/widgets/analytics/activity_chart.dart`: Bar chart component.
- `mobile/lib/widgets/analytics/proficiency_radar.dart`: Hexagonal chart component.

### [MODIFY]
- `mobile/lib/widgets/avatar/wardrobe_sheet.dart`: Repurposing as the main Analytics toggle.
- `mobile/lib/screens/game/room_screen.dart`: Update trigger to open Analytics by default.

---

## Task Breakdown

### Phase 1: Backend (Analytics Logic)
| Task ID | Name | Agent | Skills | Input -> Output -> Verify |
|---------|------|-------|--------|---------------------------|
| B1 | Create Stats aggregated query | backend-specialist | database-design | SQL aggregation of `responses` + `bloom_level` -> JSON structure -> Test via Postman |
| B2 | Implement Stats Controller/Routes | backend-specialist | api-patterns | Endpoint `/api/stats/summary` + `/api/stats/activity` -> Aggregated data -> Verify non-zero values |

### Phase 2: Mobile (Dashboard Foundation)
| Task ID | Name | Agent | Skills | Input -> Output -> Verify |
|---------|------|-------|--------|---------------------------|
| M1 | Repurpose Wardrobe Sheet UI | mobile-developer | frontend-design | Medical Network style card + Header + Bottom Nav buttons -> Visual match to screenshots |
| M2 | Implement Activity Bar Chart | mobile-developer | react-patterns | `fl_chart` integration -> Visual bars for Day/Week/Month -> Mock data check |

### Phase 3: Mobile (Mastery & Radar)
| Task ID | Name | Agent | Skills | Input -> Output -> Verify |
|---------|------|-------|--------|---------------------------|
| M3 | Implement Subject Mastery Tiles | mobile-developer | frontend-design | Interactive tiles in ScrollView -> Click trigger -> Verify zoom transition trigger |
| M4 | Implement Hexagonal Radar Chart | mobile-developer | react-patterns | `RadarChart` from `fl_chart` -> Visual hexagon with 6 axes -> Verify data mapping |
| M5 | Add Zoom Transitions | mobile-developer | frontend-design | `AnimatedSwitcher` logic -> Zoom in on click, zoom out on back -> Seamless "folder" feel |

---

## Phase X: Verification
- [ ] **Security**: Verify `/api/stats` is protected by JWT (User can't see others' stats).
- [ ] **UX Audit**: Verify charts are readable on smaller mobile screens.
- [ ] **Data Integrity**: Verify Bloom level calculations match `correct_answer` count in DB.
- [ ] **Performance**: Verify aggregation query doesn't lag the DB (Add indexes if needed).

---
## ✅ PHASE X COMPLETE
- Date: [TBD]
