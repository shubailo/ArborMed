# Project Plan: ArborMed 2.0 (Med-Buddy Core) Refactor

## 🔴 Overview
Az ArborMed 2.0 alkalmazás építészeti és pedagógiai motorjának teljes refaktorálása, amely egy robusztusabb, skálázhatóbb ökoszisztémát hoz létre a hallgatói iOS/Android felület és a Next.js professzori analitikák számára.

## 🔴 Project Type
MOBILE (Flutter student app) & WEB (Next.js professor dashboard) & BACKEND (Node.js/Express)

## 🔴 Success Criteria
1. **Melos Monorepo szerkezet:** Tiszta, körkörös függőségektől és `spaghetti kódtól` mentes csomagszerkezet kialakítása (`core`, `features`, `apps`).
2. **Pedagógiai Motor modernizáció:** Az elavult SM-2 motor FSRS (Free Spaced Repetition Scheduler) algoritmusra cserélése ($D_0$ nehézségi inicializálás Bloom-szintekkel) beépített Post-Inactivity Load Balancer-rel.
3. **Flame Engine stabilitás:** A játéktér (Cozy Room) drag-and-drop Y-koordináta alapú (Z-index "Bottom-Most Pivot") rétegkezelése hibátlanul üzemel, és integrálja a `Riverpod / BLoC` Event Bracket-et.
4. **Adatvizualizáció Dashboard:** A `prof-dashboard` a "Learning Analytics" indikátorokat és a Bloom-hiány (Coverage Gap) diagramokat biztosítja.

## 🔴 Tech Stack
- **Flutter Framework:** UI, Riverpod, GoRouter, Dio
- **Kliens Motor (Game Engine):** Flame (`flame_bloc` vagy `flame_riverpod`, `ScaleEffect`, `MoveEffect`)
- **Package Management:** Melos
- **FSRS Motor:** dart-fsrs / fsrs-rs-dart
- **Irányítópult:** Next.js 14+ (App Router), React Server Components, Tailwind CSS, Prisma ORM, Recharts
- **Backend:** Node.js, Express, SQLite/PostgreSQL

## 🔴 File Structure
```text
arbormed_workspace/
├── apps/
│   ├── student_app/         # Flutter UI / Shell app
│   └── prof-dashboard/      # Next.js web application
├── packages/
│   ├── core/                # Megosztott hálózati réteg, design rendszer, telemetria
│   ├── features/
│   │   ├── feature_study/   # Kvíz és FSRS + Bloom tanulási logika
│   │   ├── feature_reward/  # Tokenek, Shop és Quests (Riverpod állapottér)
│   │   └── feature_room/    # Flame szobamotor (mátrix konverziókkal, Z-index-szel)
│   └── shared-types/        # Megosztott DTO-k
├── services/
│   └── backend/             # Node.js REST API
├── melos.yaml               # Monorepo konfiguráció
└── package.json
```

## 🔴 Task Breakdown

### Phase 1: Csomagszintű Architektúra (P0)
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|---|---|---|---|---|---|---|
| TASK-01 | Setup Melos Workspace | `orchestrator` | `bash-linux`, `app-builder` | P0 | None | **INPUT**: Alap project folder. <br>**OUTPUT**: `melos.yaml` beállítása a monorepohoz (lásd: Implementation Details). <br>**VERIFY**: `melos bootstrap` lefut, körkörös függőség nélkül összeköti a csomagokat. |
| TASK-02 | Extract Feature / Core Packages | `mobile-developer` | `dart-patterns` | P0 | TASK-01 | **INPUT**: Jelenlegi Flutter kód. <br>**OUTPUT**: Külön `pubspec.yaml`-ek a `core`, `feature_study`, `feature_reward` modulokban. <br>**VERIFY**: Fejlesztői környezet (IDE) önállóan is felismeri és lefordítja a csomagokat. |

### Phase 2: FSRS és Pedagógiai Intelligencia (P1)
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|---|---|---|---|---|---|---|
| TASK-03 | Integrate FSRS Engine & Load Balancer | `mobile-developer` | `clean-code` | P1 | TASK-02 | **INPUT**: Lokális/aszinkron Kvíz események (StudySession). <br>**OUTPUT**: Dart alapú FSRS számítási szerviz, beépített **Post-Inactivity Load Balancer**-rel (5-7 napos backlog elosztás). <br>**VERIFY**: Inaktivitás után a kártyák eloszlanak az ablakban; első hiba nem rontja drasztikusan az S-értéket. |
| TASK-04 | Bloom Taxonomy Weighted Difficulty | `mobile-developer` | `clean-code` | P1 | TASK-03 | **INPUT**: Bloom szintek (1-6). <br>**OUTPUT**: Kezdeti FSRS nehézséget ($D_0$) súlyozó logika az FSRS-Bloom Mátrix alapján. <br>**VERIFY**: Analízis szintű ($Lvl 4$) kártyák kezdeti stabilitása (S) alacsonyabb értékről indul. |

### Phase 3: Flame Engine és Állapot Konszolidáció (P1)
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|---|---|---|---|---|---|---|
| TASK-05 | Adopt flame_riverpod / flame_bloc | `game-developer` | `game-development` | P1 | TASK-02 | **INPUT**: BLoC és Riverpod (kevert állapotok). <br>**OUTPUT**: Egységes állapot Híd (Event Bridge). <br>**VERIFY**: Shopban vásárolt elem valós időben elérhető a Szobában is, memóriaszivárgás nélkül. |
| TASK-06 | Isometric Math & Bottom-Most Pivot | `game-developer` | `game-development` | P1 | TASK-05 | **INPUT**: Izometrikus rács és tile méretek. <br>**OUTPUT**: Cartesian képernyő -> Sprite mátrix konverziók; dinamikus Z-index a **Bottom-Most Pivot** stratégia alapján. <br>**VERIFY**: Magas vagy multi-cell bútorok is helyesen takarják a mögöttük/fölöttük lévő kisebb tárgyakat. |
| TASK-07 | Tactile UX: Feedback & Snapping | `game-developer` | `game-development` | P2 | TASK-06 | **INPUT**: Drag-and-drop események a bútoron. <br>**OUTPUT**: `ScaleEffect` pozícionáláskor; `MoveEffect` snap-back érvénytelen rácsnál. <br>**VERIFY**: Ha a diák piros rácsra (tiltott) teszi a tárgyat, visszapattan az eredeti blokkjára (`Curves.easeOutBack`). |

### Phase 4: Professzori Irányítópult / Next.js (P2)
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|---|---|---|---|---|---|---|
| TASK-08 | Initialize Prof-Dashboard App | `frontend-specialist` | `react-best-practices` | P2 | None | **INPUT**: Adatbázis sémák. <br>**OUTPUT**: `apps/prof-dashboard` Next.js 14+ alapok React Server komponensekkel, tRPC. <br>**VERIFY**: A dashboard dev szervere port ütközés nélkül indul lokálisan. |
| TASK-09 | Recharts Analytics & Bloom Gaps | `frontend-specialist` | `frontend-design` | P2 | TASK-08 | **INPUT**: Backend statisztikák (FSRS stablility, Retrievability). <br>**OUTPUT**: Valós idejű "Retention Over Time" és "Bloom Gap Analysis" grafikonok. <br>**VERIFY**: A tanár áttekintheti évfolyam szinten, ha az Elemzés szintű kártyák (< 45% retenció alatt vannak). |

## 🔴 Implementation Details (Socratic Gate Resolutions)

### 1. Melos Configuration (`melos.yaml`)
A projekt gyökérkönyvtárában elhelyezendő konfiguráció (TASK-01) a workspace szinkronizáláshoz:
```yaml
name: arbormed_workspace
repository: https://github.com/shubailo/ArborMed

packages:
  - apps/**
  - packages/**
  - packages/features/**

command:
  bootstrap:
    usePubspecOverrides: true
  version:
    generateHashes: true

scripts:
  test:all:
    run: melos run test --no-select
    description: Run all tests in the workspace.

  analyze:
    run: melos exec -- "flutter analyze"
    description: Run dart analyzer for all packages.

  build:features:
    run: melos exec --scope="*feature*" -- "flutter pub run build_runner build --delete-conflicting-outputs"
    description: Generate code for all feature packages.
```

### 2. Algoritmikus Load Balancer Inaktivitás Esetére (TASK-03)
A **Post-Inactivity Load Balancer** mechanizmus feladata a kognitív torlódás (backlog) elkerülése, anélkül, hogy „megfagasztaná” a felejtési görbét.
- **Backlog Redistribution:** A felgyülemlett kártyákat egy 5-7 napos „felzárkóztató ablakba” (sliding window) osztja el.
- **Stability Protection (Forgive):** Inaktivitás utáni első sikertelen válasz estén visszatérési bónuszt számol (a büntetés nem olyan drasztikus).

### 3. FSRS-Bloom Súlyozási Mátrix (TASK-04)
A kezdeti nehézség (Difficulty, $D_0$) beállítása a Bloom-szint alapján:
- Lvl 1-2 (Remember): Alacsony ($D_0 \approx 3-5$), Kisebb stabilitási szorzó.
- Lvl 3 (Apply): Közepes ($D_0 \approx 6-7$).
- Lvl 4-5 (Analyze, Evaluate): Magas ($D_0 \approx 7-9$).
- Lvl 6 (Create): Kritikus ($D_0 \approx 9-10$), Magas stabiliási követelmény.

### 4. Izometrikus Dinamikus Z-Index "Bottom-Most Pivot" (TASK-06)
A Flame Z-Index (Priority) nem a statikus Y koordináta, hanem a footprint "legalsó" pontja alapján iterálódik (hogy multi-cell 1x2, 2x2 vagy felnyúló spriteok is helyesen takarjanak).
```dart
class FurnitureComponent extends SpriteComponent with HasGridPosition {
  @override
  void update(double dt) {
    // A priority-t a footprint legközelebbi pontja adja meg
    priority = (gridPosition.x + sizeInCells.x + gridPosition.y + sizeInCells.y).toInt();
  }
}
```

## 🔴 Phase X: Végső Verifikáció és Integrációs Tesztek
- [ ] Linterek és type-check lefut (Dart Analyzer és TS Compiler).
- [ ] Csomagfüggőségek (`melos run test`) átmennek.
- [ ] Flame Z-index és Izometrikus rács matematikája Unit teszttel lefedett (Bútor átfedés tesztelés).
- [ ] Next.js Prisma sémák és JWT/NextAuth hitelesítés auditálva.
- [ ] Végleges projekt audit script hiba nélkül lefut (`verify_all.py`).
