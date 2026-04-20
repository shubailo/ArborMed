# Projekt Javaslat: AGOOM (Adaptív, Gamifikált Orvosi Oktatási Módszertan)
## PoC Pályázati Anyag – Átdolgozott Változat

### I. A PROJEKT ÖSSZEFOGLALÁSA ÉS CÉLKITŰZÉSEI

**A projekt címe:** Adaptív, gamifikált módszertani keretrendszer és MVP koncepció a kritikus orvosi gondolkodás fejlesztésére.
**Projektvezető:** Dr. Garami András (PTE ÁOK Transzlációs Medicina Intézet)
**Kategória:** 30 – 50 millió Ft (PoC fázis)

#### 1. A PROBLÉMA: Hallgatói motivációvesztés és lexikális túlterheltség
Az orvosi alapképzés egyik legnagyobb kihívása a hallgatói motiváció drasztikus csökkenése a szorgalmi időszak közepén (az úgynevezett "félévközi hullámvölgy"). A jelenlegi oktatási módszerek többsége:
- **Passzív:** Az előadásokon a hallgatók befogadók, nem interaktív résztvevők.
- **Lexikális fókuszú:** A vizsgák gyakran a puszta tényanyag visszakérdezésére (rote memorization) épülnek, nem a klinikai összefüggések átlátására.
- **Alacsony megtartási arány:** A bemagolt tudás a vizsga után gyorsan kopik, mivel nem épül be stabil, strukturált tudástárba.

#### 2. A MEGOLDÁS: Az AGOOM módszertani keretrendszer
A projekt célja nem egy egyszerű kvíz-applikáció fejlesztése, hanem egy **átfogó oktatási módszertan (AGOOM)** kidolgozása és annak technológiai validálása egy **MVP (Minimum Viable Prototype)** szintű koncepción keresztül. A megoldás három innovatív pillérre épül:

1.  **Adaptív "Gondolkodtató" Engine:** A rendszer nem csak kérdéseket tesz fel, hanem a hallgató kognitív terheléséhez igazodva "vezeti" őt az egyszerű felidézéstől a komplex klinikai elemzésig (Bloom-taxonómia).
2.  **Pszichológiai Motivációs Hurok:** Gamifikációs elemekkel (visual clinic, streak-rendszer, peer-to-peer duellek) érjük el, hogy a hallgatók ne kényszernek, hanem belső késztetésnek érezzék a napi szintű gyakorlást.
3.  **Adatvezérelt Oktatói Felügyelet:** Az oktatók számára egy olyan dashboard tervét hozzuk létre, amely valós időben mutatja meg, hol vannak a hallgatók tudásában a "vakfoltok", így a tantermi oktatás célzottabbá válhat.

---

### II. A MÓDSZERTAN ÉS A QUIZ ENGINE MECHANIKÁJA

Az AGOOM lelke a beépített intelligens algoritmus, amely a puszta értékelés helyett valódi tanítási folyamatot valósít meg.

#### 1. Bloom Climber (A tudás létrája)
A rendszer a Bloom-taxonómia szintjei mentén mozgatja a hallgatót. Kezdetben alapszintű definíciókat és tényeket kérdez (Level 1-2), de amint a hallgató stabilitást mutat, automatikusan vált át komplex klinikai esetekre és differenciáldiagnosztikai kérdésekre (Level 3-4). 
*Cél: A hallgató ne csak tudja az adatot, hanem tudja HASZNÁLNI is.*

#### 2. SRS (Spaced Repetition System) & SM-2 Algoritmus
A tananyag elfelejtésének megakadályozására a rendszer az SM-2 (Spaced Repetition) algoritmus modernizált változatát használja. Minden kérdésnél méri a válaszadás minőségét és idejét, majd pontosan akkor dobja vissza a kérdést ismétlésre, amikor az a leghatékonyabban rögzül a hosszú távú memóriában.

#### 3. Diagnosztikai "Fail-Down" mechanizmus
Ez az egyik legfontosabb újdonság: ha egy hallgató elbukik egy magas szintű (L3-L4) kérdésen, a rendszer nem csak annyit mond, hogy "helytelen". Ehelyett a háttérben megkeresi a kérdéshez rendelt alapvető előfeltételeket (prerequisites), és "csendben" visszalépteti a hallgatót az alapokhoz, hogy feltöltse a tudásbeli hiányosságot a gyökerénél.

#### 4. Súlyozott Mastery Score
A pontozás nem lineáris. A komplexebb, gondolkodást igénylő kérdések (L3-L4) nagyobb súllyal esnek latba a "Mastery Score" számításakor, mint az egyszerű kérdések. Ez arra ösztönzi a hallgatókat, hogy a mélyebb megértésre törekedjenek.

#### 5. Taktikai Eset-Párbaj (Tactical Case Duel)
A multiplayer élmény csúcspontja, ahol a sebesség és a precizitás találkozik. A hallgatók nem véletlenszerű kvízkérdésekben, hanem **közös klinikai esetek (CBL) megoldásában** mérik össze tudásukat.
- **Fázis-alapú küzdelem**: A párbaj a diagnózistól a terápiás döntésekig tart.
- **Stabilitás-alapú pontozás**: Egy rossz döntés nem csak pontlevonást jelent, hanem a játékos "klinikai stabilitásának" romlását, ami közvetlen visszacsatolást ad a szakmai hiba súlyáról.
- **Adrenalin + Logika**: A versenyhelyzet fenntartja az izgalmat, de az eset-alapú kérdések megakadályozzák a puszta tippelést ( guessing-prevention).

#### 6. AI Content Miner (Automata Tartalomgenerálás)
A fenntarthatóság záloga. Egy olyan **RAG (Retrieval-Augmented Generation)** alapú modul, amely képes orvosi szakirodalomból (szakkönyvek, guideline-ok) automatizáltan, de szakmailag validált módon Bloom-szintezett kérdésbankokat építeni.
- **Többágensű Audit**: Minden generált kérdést egy külön "Kritikus AI ágens" ellenőriz, mielőtt az oktató elé kerülne jóváhagyásra.
- **Emberi Felügyelet**: Az oktató nem írja a kérdést, hanem auditálja, ami 80%-os időmegtakarítást jelent.

---

### III. HALLGATÓI MOTIVÁCIÓ ÉS RETENCIÓ

A projekt kiemelt célja, hogy megoldást nyújtson a hallgatói inaktivitásra.

- **Dinamikus Gamifikáció:** A hallgatók nem csak pontokat gyűjtenek. A "Virtual Clinic" (saját vizuális tér) fejlesztése, az összegyűjtött "Stethoscopes" (tokenek) és a ritka tárgyak megszerzése vizuális visszacsatolást ad a tudás gyarapodásáról.
- **Duel Arena:** A multiplayer funkció lehetővé teszi a baráti versengést (triviador-szerű mechanika), ami a közösségi tanulást és a gyakori visszatérést (daily engagement) serkenti.
- **Folyamatjelzők és Streak:** A rendszer pszichológiai "jutalmazási útvonalakat" (dopamin-hurkokat) használ, hogy a szorgalmi időszak alatt is fenntartsa az érdeklődést.

---

### IV. A RENDSZER KÉT OLDALA: OKTATÓI ÉS FELHASZNÁLÓI PERSPEKTÍVA

Az AGOOM sikerének kulcsa, hogy mindkét érdekelt fél számára valódi értéket teremt, megoldva a jelenlegi oktatási rendszer fájdalmas pontjait.

#### 1. Oktatói oldal: Adatvezérelt kontroll és adminisztrációs tehermentesítés
Az oktatók számára a rendszer nem plusz munkát, hanem egy hatékony **döntéstámogató eszközt** jelent:
- **Learning Analytics Dashboard**: Valós idejű statisztika a hallgatók teljesítményéről. Az oktató pontosan látja, melyik témakör (pl. sav-bázis háztartás) okoz nehézséget a csoportnak, így a tantermi órát célzottan azokra a részekre fókuszálhatja, ahol tényleges "tudás-lyukak" vannak.
- **Kérdésbank Menedzsment**: Egyszerűsített, Excel-alapú tömeges tartalomfeltöltés, amely automatikusan kezeli a Bloom-szinteket és a nyelvi változatokat (HU/EN).
- **Vakfolt-analízis**: A rendszer azonosítja azokat a kérdéseket, amelyeket a hallgatók többsége elront, így az oktató finomíthatja a tananyagot vagy a kérdések megfogalmazását.

#### 2. Felhasználói (Hallgatói) oldal: Személyre szabott élmény és motiváció
A hallgató számára a tanulás folyamata egy **izgalmas felfedezéssé** válik:
- **Intelligens Tanösvény**: Nincs több felesleges ismétlés. A rendszer tudja, mit tud már a hallgató, és csak a szükséges mértékben és időpontban (SRS) hozza vissza az anyagot.
- **Taktikai Eset-Párbajok**: A multiplayer faktor nem csak játék, hanem a tudás "stressz-tesztje" egy biztonságos, versengő környezetben.
- **Vizuális Építkezés (Clinic)**: A tanulás eredménye nem csak egy jegy, hanem egy virtuális tér (klinika) látványos fejlődése, ami folyamatos sikerélményt és büszkeséget ad.
- **Kritikus Gondolkodás**: A hallgató nem passzív befogadó, hanem aktív döntéshozó, ami felkészíti őt a valós klinikai munkára.

---

### V. AZ MVP TARTALMA (PoC kimenet)

A 24 hónapos projekt végére nem egy statikus szoftver, hanem egy **validált prototípus és fejlesztési terv** jön létre:
1.  **Módszertani Specifikáció:** Teljes leírás az algoritmusokról és a pedagógiai logikáról.
2.  **Interaktív Prototípus:** Egy kattintható, vizuálisan magas minőségű mockup, amely bemutatja a hallgatói és oktatói felületeket, beleértve az AI-támogatott kérdés-audit felületet is.
3.  **Kérdésbank Architektúra:** 1500-2000 validált, Bloom-szintekkel és kapcsolatokkal (Nexus) ellátott kérdés tervrajza.
#### 4. Technológiai Roadmap: Részletes szoftver-architekturális terv (Node.js, Flutter, PWA) a skálázható megvalósításhoz, különös tekintettel a valós idejű párbaj-szinkronizációra (WebSockets).

---

### VI. RÉSZLETES VÁLASZOK A PÁLYÁZATI KATEGÓRIÁKHOZ

Az alábbi szakaszok közvetlenül felhasználhatóak a pályázati űrlap kitöltéséhez, dinamikus és meggyőző stílusban.

#### 1. A projekt leírása (Megoldandó probléma, megoldás, újdonságtartalom)
*Kulcsszavak: Passzív oktatás kivezetése, Hallgatói elkötelezettség, Gondolkodás-alapú mérés.*

**Leírás:** 
Az orvosképzés legnagyobb gátja ma a hallgatók passzivitása. A hagyományos, tömbszerű oktatás nem képes fenntartani a figyelmet az év közbeni "szürke hetekben", ami a vizsgaidőszakban kapkodó, felületes tanuláshoz vezet. Az **AGOOM (Adaptív, Gamifikált Orvosi Oktatási Módszertan)** ezt a dinamikát töri meg. 

A megoldásunk lényege a **"Gondolkodási Hurok"**: a rendszer nem elégszik meg a helyes válasszal, hanem a Bloom-taxonómia magasabb szintjeire (analízis, szintézis) kényszeríti a hallgatót. Az algoritmusunk (SM-2 alapú SRS) biztosítja, hogy a megszerzett tudás ne vesszen el, míg a gamifikációs réteg (PvP párbajok, vizuális klinika-építés) a hallgatót arra motiválja, hogy naponta többször is önként térjen vissza az anyaghoz. Az újdonságunk nem csak a technológiában, hanem az integrált pedagógiai szemléletben rejlik: a diagnosztikai mechanizmusunk automatikusan felismeri, ha egy hallgatónak alapozó hiányosságai vannak, és célzottan, de észrevétlenül pótolja azokat.

#### 2. Az innovációt indokló piaci/társadalmi igény
*Kulcsszavak: Orvosi burnout megelőzése, Skill-gap csökkentése, Digitális transzformáció.*

**Leírás:** 
A modern orvosképzésben tátongó szakadék van a lexikális tudás és a klinikai döntéshozatal között. A piac és az egészségügyi intézmények olyan rezidenseket igényelnek, akik képesek kritikus helyzetekben gyorsan és logikusan dönteni. Társadalmi szinten az orvosi burnout már a hallgatói évek alatt elkezdődik az óriási, rendszerezetlen tananyag miatt. Az AGOOM csökkenti ezt a terhelést azáltal, hogy személyre szabott, kezelhető és élvezetes tanulási útvonalat kínál. Az EU Digitális Oktatási Akcióterveivel összhangban a PTE ezzel a módszertannal az orvosképzési innováció élvonalába kerülhet, választ adva a Z-generációs hallgatók megváltozott tanulási igényeire.

#### 3. A PoC keretében létrejövő eredmények (Üzleti hasznosíthatóság)
*Kulcsszavak: PTE Spin-off potenciál, Licencálható módszertan, Validált kérdésbank.*

**Leírás:** 
A 24 hónapos PoC fázis végére egy befektetésre érett **módszertani és technológiai csomag (MVP)** áll rendelkezésre. Ez tartalmazza:
- A teljesen validált, 1500+ kérdésből álló "Gondolkodtató" kérdésbankot.
- Az adaptív és gamifikációs algoritmusok dokumentált forráskódját és logikai prototípusát.
- Az **AI Content Miner** modul technikai specifikációját és tesztelt prompt-architektúráját.
- Egy interaktív, kattintható mockupot, amely készen áll a skálázható szoftverfejlesztésre.
A hasznosítási modellünk SaaS (Software as a Service) alapú, amely nemcsak a PTE-n belül, hanem országos és nemzetközi szinten is licencálható más orvosegyetemek vagy szakmai továbbképző központok számára, akár egy későbbi PTE spin-off vállalkozás keretében.

#### 4. Piacra lépési és jövőbeli fejlesztési igények
*Kulcsszavak: Skálázhatóság, AI-támogatott kérdésgenerálás, LMS integráció.*

**Leírás:** 
A PoC lezárulta utáni következő lépés a teljes körű szoftverfejlesztés (iOS/Android) és az olyan nagy oktatási rendszerekbe (Moodle, Canvas) való integráció, mint a PTE saját LMS-e. A távoli jövőben a keretrendszert AI-modulokkal kívánjuk bővítene, amelyek automatikusan generálnak minőségi kérdéseket orvosi szakkönyvekből, tovább csökkentve az oktatók adminisztrációs terheit. A célunk, hogy az AGOOM ne csak egy eszköz, hanem az orvosi oktatás új standardja legyen.
