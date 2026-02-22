# FINAL SPEC FOR GEMINI – ArborMed 2.0 Core Loop & Room Engine

**Cél:** összefoglaló specifikáció, amely alapján a teljes „quiz → tokens → quests → shop → inventory → room (Flame)” motivációs rendszer stabilan újraimplementálható / refaktorálható (Android + Web Flutter‑buildre).

---

## 1. Platform & architektúra
**Platformok:** Android telefon + Flutter Web (desktop böngésző).

**Fő technológiák:**
- **Flutter** (Riverpod alapú app‑state + UI).
- **Flame** (Room minijáték, 2D izometrikus dekorációs szoba).
- **BLoC** az engine‑hez (`RoomEngineBloc`) – UDF elv a játéklogikában.

**UDF adatfolyam (összkép):**
`Quiz` → `Tokens` (RewardBalance) →
`Quests` (extra tokens) →
`Shop` (ShopItem vásárlás) →
`Inventory` (Owned items, Available vs Placed) →
`RoomEngineBloc` (RoomItem state) →
`Flame RoomGame` (vizuális dekorálás).

---

## 2. Study / Quiz modul
### 2.1. Fő cél
A kvíz a tanulás fő terepe; a meta‑játék csak ráépül.

### 2.2. Fő elemek
- **`quiz_page.dart`**:
  - Mutatja a kérdéseket, kezeli az aktuális sessiont.
  - `_sessionQuestions`, `_sessionLimit` alapján zárja le a sessiont.
- **`QuizHeaderWidget`**:
  - Mutatja az aktuális kérdés sorszámát (Question X of Y vagy progress bar).
  - Mutatja az aktuális token egyenleget (`🩺 RewardBalance.tokens`).

### 2.3. Session Summary (Result Screen)
**Fájl:** `session_summary_page.dart`

**Megjelenítés:**
1. **Összefoglaló:** Hány kérdést válaszolt meg, hány volt helyes. Rövid pozitív szöveg (pl. „Nice work!”, „Great job!”) performance alapján.
2. **Rewards:** „You earned +X 🩺 this session.” – pontos token mennyiség.
3. **Quests:** Ha van `LearningQuest.status == completed & !claimed`: Pezsgőszínű buborék: „You have quests ready to claim!”.
4. **Navigációs gombok:**
   - Continue Learning – új quiz / vissza a tanulási listához.
   - Shop – nyitja a token shopot.
   - My Room – nyitja a Flame room screen‑t.
   - View Quests – csak akkor aktív, ha van claimelhető quest.

**Navigációs viselkedés:**
- A result screen `Navigator.push<String>`-kel tér vissza a QuizPage felé, ahol a visszakapott „intent” alapján tisztán elhagyja a quiz stack‑et, ha Room/Shop/Quests irányba megy.

---

## 3. Rewards & Tokens (RewardBalance)
### 3.1. Entitások
- **`RewardBalance`**: `int tokens`.
- **Fő operációk:** `earnTokens(int amount)`, `spendTokens(int amount) -> bool`.

### 3.2. Források
- **Base tokens:** Quiz session befejezésekor számolt jutalom (pl. pontszám / helyes válaszok alapján).
- **Extra tokens:** Quests Claim során.

### 3.3. Riverpod
- **`reward_providers.dart`**: `rewardBalanceProvider` (StateNotifier / Notifier), `rewardControllerProvider` (publikus API: `earnTokens()`, `spendTokens()`).

---

## 4. Daily / Weekly Quests modul
### 4.1. Cél
Rendszeres visszatérést és tanulási szokást építeni, nem FOMO‑t.

### 4.2. Modell
- **`LearningQuest`**: `String id`, `QuestPeriod period` (daily, weekly), `String title`, `String description`, `int targetCount`, `int currentCount`, `QuestStatus status` (active, completed, claimed), `int rewardTokens`.

### 4.3. QuestNotifier (Riverpod)
**Fájlok:** `quest_entities.dart`, `quest_providers.dart`
- **`initQuests()`**: Ellenőrzi, történt‑e nap / hét váltás (`lastResetDate` vs `now`). Ha igen, új, fix vagy véletlenszerű quest listát generál.
- **`onQuizCompleted(QuizResult result)`**: Növeli a `currentCount`-ot. Ha eléri a cél, `status = completed`.
- **`claimQuest(String id)`**: Csak completed questre hívja a `rewardControllerProvider.earnTokens(rewardTokens)`-t, status lesz `claimed`.

### 4.4. Quests UI (Cozy overlay)
- **`quests_panel.dart`**: Flutter overlay (nem Flame UI).
- A room HUD jobb alsó sarkából felugró panel (jegyzetfüzet ikon).
- Ha completed és !claimed: „Claim reward (+X 🩺)” gomb.

---

## 5. Shop & Inventory modul
### 5.1. Shop (DecorateShopModal)
- Tabok: Shop tab (vásárlás), Inventory tab (My Items).
- **`ShopItem`**: `String id`, `String name`, `int priceTokens`, `String roomItemType / template id` stb.
- **Buy gomb:** Meghívja a `spendTokens()`-t. Siker esetén `UserInventoryItem`-et ad az inventory state-hez. Nincs közvetlen spawn.

### 5.2. Inventory („My Items” tab)
- **`UserInventoryItem`**: `String id`, `String shopItemId`, `int quantity`.
- **UI (`_InventoryItemCard`)**: Összegzi a `quantity`-t, majd levonja belőle a `RoomState`-ben lerakottak számát = Available.
- **„Place in room” gomb (ha Available > 0):** Generál default slotKey (2,2) RoomItemet. `ItemUnlocked(RoomItem)` eventet lő a `RoomEngineBloc` felé, ablak bezárul.

---

## 6. Room Engine (Flame + BLoC)
### 6.1. Fő komponensek
- **`RoomGame` (Flame GameWidget)**: Bridge a Flutter UI ↔ Flame világ között.
- **`_RoomWorld`**: Flame World. BLoC state-t szinkronizál; létrehoz és töröl `FurnitureComponent`-eket.
- **`RoomEngineBloc`**: Adatforrás. Eventek: `ItemUnlocked`, `FurnitureMoved`.
- **`PlacementValidator` (MVP 5×5):** Foglalt cellák jelölése (`freeArea` / `occupyArea`).

### 6.2. FurnitureComponent (Flame)
`extends PositionComponent with DragCallbacks`:
- **`onDragStart`**: `_isAnimatingBack` guard, `PlacementValidator.freeArea` saját cellára.
- **`onDragUpdate`**: Kiszámolja a cél grid cellát (`IsometricUtils.screenToGrid`). GridHighlightComponent valid-invalid megvilágítása a Custom hover effectel (pirosas tint invalid esetén).
- **`onDragEnd`**: 
  - Valid: Lő egy `FurnitureMoved` eventet a BLoC-nak, majd egy Bounce `ScaleEffect` fut le.
  - Invalid: Flame `MoveEffect` futtatása vissza a kiinduló helyére, és az `_isAnimatingBack` bekapcsolása.

### 6.3. Invalid drop animáció (snap-back)
- `MoveEffect.to(IsometricUtils.gridToScreen(oldGridCell), EffectController(duration: 0.2, curve: Curves.easeOut))`
- Guard: `_isAnimatingBack` flag megakadályozza a húzást az animáció alatt.

### 6.4. Valid drop „satisfying” animáció
- `ScaleEffect.to(Vector2(1.2, 1.2), EffectController(duration: 0.12, curve: Curves.easeOutBack))`

### 6.5. GridHighlightComponent
- Kiemeli az ujj / egér mutató alatti izometrikus rácsot valid (fehér) és invalid (piros) overlayek segítségével drag esetén.

### 6.6. Empty Room UX
- Szöveges útmutatás üres szoba esetén: „Earn tokens by solving quizzes, then buy items in the shop to decorate your room.” (`CozyActionsOverlay`).

---

## 7. Android vs Web szempontok
- Kerüld az `int` overflowt kalkulációknál, használd a `double`-t, ha szükséges a pozícióknál.
- **Web**: Figyelj a texture méretekre és a Flame performance-re.

---

## 8. Összefoglaló modul‑lista Gemininek
1. `lib/features/study/` (Quiz UI, Session Summary)
2. `lib/features/rewards/` (Tokens)
3. `lib/features/quests/` (QuestNotifier)
4. `lib/features/shop/` (Buy Flow)
5. `lib/features/inventory/` (Place in room)
6. `lib/features/room/` (Flame Room Engine)

**Minőség:**  
UDF betartása, `flutter analyze` clean, as well as keeping `Release` mode optimized.
