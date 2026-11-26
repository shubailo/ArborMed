// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'ArborMed';

  @override
  String get authLogin => 'Bejelentkezés';

  @override
  String get authLearn => 'Orvosi tanulás';

  @override
  String get authIdentifier => 'E-mail-cím vagy felhasználónév';

  @override
  String get authRequired => 'Kötelező mező';

  @override
  String get authPassword => 'Jelszó';

  @override
  String get authShow => 'Jelszó megjelenítése';

  @override
  String get authHide => 'Jelszó elrejtése';

  @override
  String get authShort => 'Túl rövid';

  @override
  String get authForgotLink => 'Elfelejtetted a jelszavad?';

  @override
  String get authNoAccount => 'Még nincs fiókod? ';

  @override
  String get authCreateLink => 'Regisztrálj';

  @override
  String get authForgot => 'Elfelejtett jelszó';

  @override
  String get authResetTitle => 'Jelszó visszaállítása';

  @override
  String get authEmailPrompt => 'Add meg az e-mail-címed.';

  @override
  String get authCodePrompt => 'Add meg a hatjegyű kódot.';

  @override
  String get authResetSuccess =>
      'A jelszavad megváltozott. Jelentkezz be az új jelszóval.';

  @override
  String get authTryAgain => 'Próbáld újra.';

  @override
  String get authResetHelp =>
      'Add meg az e-mail-címed, és küldünk egy hatjegyű visszaállító kódot.';

  @override
  String get authEmail => 'E-mail-cím';

  @override
  String get authOtp => 'Hatjegyű kód';

  @override
  String get authShowNew => 'Új jelszó megjelenítése';

  @override
  String get authHideNew => 'Új jelszó elrejtése';

  @override
  String get authSendCode => 'Kód küldése';

  @override
  String get authReset => 'Visszaállítás';

  @override
  String get authJoin => 'Csatlakozz az ArborMedhez';

  @override
  String get authJourney => 'Hozd létre a tanulói fiókodat';

  @override
  String get authEmailRequired => 'Add meg az e-mail-címed';

  @override
  String get authEmailInvalid => 'Adj meg érvényes e-mail-címet';

  @override
  String get authHandle => 'Felhasználónév (@név)';

  @override
  String get authUserRequired => 'Add meg a felhasználóneved';

  @override
  String get authDisplayName => 'Megjelenített név';

  @override
  String get authDisplayRequired => 'Add meg a megjelenített neved';

  @override
  String get authPasswordRequired => 'Add meg a jelszavad';

  @override
  String get authMinLength => 'Legalább 8 karakter szükséges';

  @override
  String get authUpper => 'Legalább egy nagybetű szükséges';

  @override
  String get authNumber => 'Legalább egy számjegy szükséges';

  @override
  String get authSpecial => 'Legalább egy különleges karakter szükséges';

  @override
  String get authCreate => 'Fiók létrehozása';

  @override
  String get authExisting => 'Van már fiókod? ';

  @override
  String authCodeSent(String email) {
    return 'A kódot ide küldtük: $email';
  }

  @override
  String authRegFailed(String reason) {
    return 'Sikertelen regisztráció: $reason';
  }

  @override
  String quizPreparingSystem(String system) {
    return '$system – a kvíz előkészítése';
  }

  @override
  String get quizLoadFailed => 'A kvízt nem sikerült betölteni';

  @override
  String get quizLoadRetryHint =>
      'Lépj vissza az előző képernyőre, és próbáld újra.';

  @override
  String get quizSelectAllCorrect => 'Válassz ki minden helyes választ!';

  @override
  String get adminMatchingRepairKey =>
      'A tárolt megoldókulcs eltér a pároktól. A megjelenített párokat mentem új megoldókulcsként.';

  @override
  String get adminMatchingMinimum => 'Adj meg legalább két párt.';

  @override
  String get adminMatchingDuplicate =>
      'Ebben az oszlopban minden feliratnak egyedinek kell lennie.';

  @override
  String get quizMatchPairs => 'Párosítsd a kifejezéseket!';

  @override
  String quizPairedWith(String term) {
    return 'Kiválasztott pár: $term';
  }

  @override
  String get quizNoOptions => 'Nincsenek válaszlehetőségek.';

  @override
  String get quizEnlargeImage => 'Koppints a kép nagyításához';

  @override
  String get mistakeReviewLoadFailed =>
      'Az időszak hibás válaszait nem sikerült betölteni. Próbáld újra.';

  @override
  String get dailyQuests => 'Napi küldetések';

  @override
  String get subjectMastery => 'Tantárgyi eredmények';

  @override
  String get analyticsTab => 'Eredmények';

  @override
  String get activityTab => 'Aktivitás';

  @override
  String get questEmpty => 'Nincs elérhető napi küldetés.';

  @override
  String get questClaim => 'Jutalom felvétele';

  @override
  String questAward(int count) {
    return 'Jóváírt jutalom: $count zseton.';
  }

  @override
  String get questClaimFailed =>
      'A jutalom jóváírását nem sikerült megerősíteni. Ellenőrizd a frissített küldetéslistát.';

  @override
  String get questRefreshFailed =>
      'A napi küldetéseket nem sikerült frissíteni.';

  @override
  String get activityLoadFailed =>
      'Az időszak aktivitását nem sikerült betölteni.';

  @override
  String get masteryLoadFailed =>
      'A tantárgyi eredményeket nem sikerült betölteni.';

  @override
  String get masteryNoSections => 'Ehhez a tantárgyhoz nincs elérhető témakör.';

  @override
  String get masteryEmpty => 'Nincs elérhető tantárgy.';

  @override
  String get activityActiveDays => 'Aktív napok';

  @override
  String get activityMonthIntensity => 'Havi aktivitás';

  @override
  String get activityEmpty => 'Ehhez az időszakhoz nincs aktivitási adat.';

  @override
  String get activityLess => 'Kevesebb';

  @override
  String get activityMore => 'Több';

  @override
  String activityCorrectCount(int count) {
    return '$count helyes válasz';
  }

  @override
  String get quizStart => 'Kvíz indítása';

  @override
  String get quizContinue => 'Folytatás';

  @override
  String get quizSubmit => 'Válasz beküldése';

  @override
  String get quizNext => 'Következő kérdés';

  @override
  String get quizFinish => 'Kvíz befejezése';

  @override
  String get quizCorrect => 'Helyes!';

  @override
  String get quizIncorrect => 'Helytelen';

  @override
  String get quizScore => 'Pontszám';

  @override
  String get quizResults => 'Kvíz eredményei';

  @override
  String get quizStudyBreak => 'Tanuló szünet';

  @override
  String get quizStartSession => 'Munkamenet indítása';

  @override
  String get quizSelectSubject => 'Válassz tantárgyat';

  @override
  String get quizComingSoon => 'Hamarosan...';

  @override
  String get quizSubjectPathophysiology => 'Kórélettan';

  @override
  String get quizSubjectPathology => 'Pathológia';

  @override
  String get quizSubjectMicrobiology => 'Mikrobiológia';

  @override
  String get quizSubjectPharmacology => 'Gyógyszertan';

  @override
  String get quizLastStudied => 'UTOLJÁRA TANULVA';

  @override
  String get quizQuoteTopic => 'Válaszd ki a mai fókuszt.';

  @override
  String get quizSubjects => 'Tárgyak';

  @override
  String get quizECG => 'EKG';

  @override
  String get duelArena => 'Párbaj Aréna';

  @override
  String get settings => 'Beállítások';

  @override
  String get language => 'Nyelv';

  @override
  String get languageEnglish => 'Angol';

  @override
  String get languageHungarian => 'Magyar';

  @override
  String get audio => 'Hang';

  @override
  String get music => 'Zene';

  @override
  String get soundEffects => 'Hangeffektusok';

  @override
  String get about => 'Névjegy';

  @override
  String get shop => 'Bolt';

  @override
  String get inventory => 'Készlet';

  @override
  String get profile => 'Profil';

  @override
  String get friends => 'Barátok';

  @override
  String get stats => 'Statisztikák';

  @override
  String get logout => 'Kijelentkezés';

  @override
  String get save => 'Mentés';

  @override
  String get cancel => 'Mégse';

  @override
  String get delete => 'Törlés';

  @override
  String get edit => 'Szerkesztés';

  @override
  String get add => 'Hozzáadás';

  @override
  String get search => 'Keresés';

  @override
  String get filter => 'Szűrés';

  @override
  String get sort => 'Rendezés';

  @override
  String get coins => 'Érmék';

  @override
  String get xp => 'XP';

  @override
  String get level => 'Szint';

  @override
  String get loading => 'Betöltés...';

  @override
  String get error => 'Hiba';

  @override
  String get success => 'Sikeres';

  @override
  String get retry => 'Újra';

  @override
  String get autoTranslate => 'Automatikus fordítás';

  @override
  String get reviewTranslation => 'Fordítás ellenőrzése';

  @override
  String get translating => 'Fordítás folyamatban...';

  @override
  String get translationFailed => 'Fordítás sikertelen';

  @override
  String get questionText => 'Kérdés';

  @override
  String get explanation => 'Magyarázat';

  @override
  String get options => 'Opciók';

  @override
  String get correctAnswer => 'Helyes válasz';

  @override
  String get difficulty => 'Nehézség';

  @override
  String get topic => 'Témakör';

  @override
  String get admin => 'Admin';

  @override
  String get questions => 'Kérdések';

  @override
  String get createQuestion => 'Kérdés létrehozása';

  @override
  String get editQuestion => 'Kérdés szerkesztése';

  @override
  String get deleteQuestion => 'Kérdés törlése';

  @override
  String get settingsTitle => 'BEÁLLÍTÁSOK';

  @override
  String get aboutApp => 'RÓLUNK';

  @override
  String get musicVolume => 'Zene hangereje';

  @override
  String get selectTrack => 'Zene kiválasztása';

  @override
  String get themeMode => 'Megjelenés';

  @override
  String get notifications => 'Értesítések';

  @override
  String get signOut => 'Kijelentkezés';

  @override
  String get adminPanel => 'Admin';

  @override
  String get appVersion => 'v0.1.0 Béta';

  @override
  String get appDescription =>
      'Az ArborMed egy tanulási segéd, amit orvostanhallgatók számára terveztünk az elméleti anyag játékos elsajátításához.';

  @override
  String get appMission =>
      'A bizonyítékokon alapuló tanulás és egy kellemes, stresszmentes környezet ötvözésével segítünk a hallgatóknak hatékonyan megbirkózni a nehéz orvosi tárgyakkal.';

  @override
  String get createdBy => 'KÉSZÍTETTE';

  @override
  String get vision => 'VÍZIÓ';

  @override
  String get visionStatement =>
      'Az orvosképzés átalakítása örömteli, jutalmazó mindennapi szokássá.';

  @override
  String get copyright => '© 2026 ArborMed Csapat';

  @override
  String get accountSettings => 'FIÓK BEÁLLÍTÁSOK';

  @override
  String get changePassword => 'Jelszó megváltoztatása';

  @override
  String get currentPassword => 'Jelenlegi jelszó';

  @override
  String get newPassword => 'Új jelszó';

  @override
  String get confirmPassword => 'Új jelszó megerősítése';

  @override
  String get update => 'FRISSÍTÉS';

  @override
  String get passwordsDoNotMatch => 'Az új jelszavak nem egyeznek';

  @override
  String get passwordChanged => 'Jelszó sikeresen megváltoztatva';

  @override
  String get changeNickname => 'Becenév megváltoztatása';

  @override
  String get nicknameHint =>
      'Ez a név lesz látható más orvosok számára az Orvosi Hálózatban.';

  @override
  String get enterNickname => 'Írd be a beceneved...';

  @override
  String get nicknameUpdated => 'Becenév frissítve!';

  @override
  String get medicalId => 'ORVOSI AZONOSÍTÓ';

  @override
  String get streak => 'SOROZAT';

  @override
  String get pager => 'CSIPOGÓ';

  @override
  String get network => 'HÁLÓZAT';

  @override
  String get searchColleagues => 'Kollégák keresése...';

  @override
  String get noDoctorsFound => 'Nem található orvos';

  @override
  String get consultRequests => 'KONZULTÁCIÓS KÉRÉSEK';

  @override
  String get colleagues => 'KOLLÉGÁK';

  @override
  String get noColleaguesYet => 'Még nincsenek kollégák. Keress rá társaidra!';

  @override
  String get removeColleague => 'Kolléga eltávolítása?';

  @override
  String areYouSureRemove(Object username) {
    return 'Biztosan el szeretnéd távolítani $username felhasználót a hálózatodból?';
  }

  @override
  String get remove => 'ELTÁVOLÍTÁS';

  @override
  String get sent => 'KÜLDVE';

  @override
  String get adminAlert => 'ADMIN RIASZTÁS';

  @override
  String get peerNote => 'Kolléga üzenete';

  @override
  String get from => 'Feladó';

  @override
  String get deleteMessage => 'Üzenet törlése?';

  @override
  String get deleteMessageConfirm =>
      'Ez a bejegyzés véglegesen törlődik a csipogódról.';

  @override
  String get yourPagerIsSilent => 'A csipogód néma.';

  @override
  String get activityTrend => 'AKTIVITÁS TREND';

  @override
  String get dailyPrescription => 'NAPI RECEPT';

  @override
  String get goalAchieved => 'CÉL ELÉRVE!';

  @override
  String get dailyDoseComplete => 'Napi adag teljesítve.';

  @override
  String needMoreToday(Object count) {
    return 'Még $count szükséges ma.';
  }

  @override
  String get mistakeReview => 'HIBÁK ÁTTEKINTÉSE';

  @override
  String reviewMistakes(Object count) {
    return 'Tekintsd át a $count hibás válaszokat.';
  }

  @override
  String get start => 'INDÍTÁS';

  @override
  String get consistency => 'KÖVETKEZETESSÉG';

  @override
  String get day => 'NAP';

  @override
  String get week => 'HÉT';

  @override
  String get month => 'HÓNAP';

  @override
  String get noMistakes => 'Nincs áttekintendő hiba ebben az időszakban!';

  @override
  String get days => 'nap';

  @override
  String get logoutOfflineWarningTitle => 'KIJELENTKEZÉS OFFLINE';

  @override
  String get logoutOfflineWarningMessage =>
      'Offline módban vagy és szinkronizálatlan adataid vannak. A kijelentkezés véglegesen törli ezeket a helyi módosításokat. Folytatod?';

  @override
  String get confirmLogoutLabel => 'KIJELENTKEZÉS MINDENKÉPP';

  @override
  String get adminDashboard => 'Vezérlőpult';

  @override
  String get adminUsers => 'Felhasználók';

  @override
  String get adminQuotes => 'Idézetek';

  @override
  String get adminQuestions => 'Kérdések';

  @override
  String get adminSettings => 'Beállítások';

  @override
  String get adminSemester => '2026 Őszi Szemeszter';

  @override
  String get adminTotalUsers => 'ÖSSZES FELHASZNÁLÓ';

  @override
  String get adminRegisteredStudents => 'Regisztrált hallgatók';

  @override
  String get adminClassAvg => 'OSZTÁLYÁTLAG';

  @override
  String get adminOverallCorrectness => 'Általános eredményesség';

  @override
  String get adminAvgBloom => 'ÁTLAGOS BLOOM SZINT';

  @override
  String get adminPedagogicalDepth => 'Pedagógiai mélység';

  @override
  String get adminTopicProficiency => 'Témakörönkénti jártasság';

  @override
  String get adminDetails => 'RÉSZLETEK';

  @override
  String get adminNoDataSubject => 'Nincs adat ehhez a tantárgyhoz';

  @override
  String get adminSuccessRate => 'Sikerességi arány';

  @override
  String get adminAvgTime => 'Átlagos idő';

  @override
  String get adminSuccessRatePercent => 'Sikerességi arány (%)';

  @override
  String get adminAvgTimeSec => 'Átlagos idő (mp)';

  @override
  String get adminQuickActions => 'Gyorsműveletek';

  @override
  String get adminImport => 'Importálás';

  @override
  String get adminReport => 'Jelentés';

  @override
  String get adminNotification => 'Értesítés';

  @override
  String get adminStudents => 'Hallgatók';

  @override
  String get adminAdministrators => 'Adminisztrátorok';

  @override
  String get adminMedicalRegistry =>
      'Orvostanhallgatói regiszter és teljesítmény';

  @override
  String get adminQuestionsUploaded => 'Feltöltött kérdések';

  @override
  String adminByAdmins(Object count) {
    return '$count admin által';
  }

  @override
  String get adminActiveUsers => 'Aktív felhasználók';

  @override
  String get adminNoUsersFound => 'Nem található felhasználó';

  @override
  String get adminSearchById => 'Keresés azonosító alapján';

  @override
  String get adminSearchStudents =>
      'Keresés hallgatói azonosító vagy e-mail-cím alapján';

  @override
  String get adminSearchAdmins => 'Keresés e-mail-cím alapján';

  @override
  String get adminDirectoryLoadFailed =>
      'Nem sikerült betölteni a felhasználók listáját.';

  @override
  String get adminHistoryLoadFailed =>
      'Nem sikerült betölteni a hallgató tanulmányi előzményeit.';

  @override
  String get adminNoStudyHistory => 'Még nincs rögzített kvízválasz.';

  @override
  String get adminStudentAccount => 'Hallgatói fiók';

  @override
  String get adminNoSubjectAssigned => 'Nincs hozzárendelt tantárgy';

  @override
  String get adminViewPerformance => 'Teljesítménytörténet megtekintése';

  @override
  String get adminTableActivity => 'AKTIVITÁS';

  @override
  String get adminTableActions => 'Műveletek';

  @override
  String get adminSendPager => 'Üzenet küldése';

  @override
  String get adminPromoteAdmin => 'Előléptetés adminná';

  @override
  String get adminDemoteStudent => 'Lefokozás hallgatóvá';

  @override
  String get adminDeleteUser => 'Felhasználó törlése';

  @override
  String adminPagerTitle(Object identifier) {
    return 'CSIPOGÓ: $identifier';
  }

  @override
  String get adminTypePagerMessage => 'Írd meg az üzeneted a hallgatónak...';

  @override
  String get adminMessageDispatched => 'Üzenet elküldve!';

  @override
  String get adminChangeRole => 'Szerepkör módosítása?';

  @override
  String adminConfirmRoleChange(Object identifier, Object role) {
    return 'Biztosan módosítani szeretnéd $identifier szerepkörét erre: $role?';
  }

  @override
  String get adminUserRoleUpdated => 'Felhasználói szerepkör frissítve!';

  @override
  String get adminDeleteUserTitle => 'Felhasználó végleges törlése?';

  @override
  String adminDeleteUserConfirm(Object identifier) {
    return 'Ez törölni fog minden haladást $identifier számára. Ez a művelet nem vonható vissza.';
  }

  @override
  String get adminDoctorRemoved => 'Orvos eltávolítva a regiszterből.';

  @override
  String get adminClickHistory => 'Kattints az előzményekért';

  @override
  String get adminNoRecordedActivity => 'Nincs rögzített aktivitás';

  @override
  String get adminCaseStudies => 'Esettanulmányok';

  @override
  String adminPageOf(Object current, Object total) {
    return '$current / $total oldal';
  }

  @override
  String get adminAddQuote => 'Új idézet hozzáadása';

  @override
  String get adminEditQuote => 'Idézet szerkesztése';

  @override
  String get adminDeleteQuote => 'Idézet törlése?';

  @override
  String get adminQuoteGallery => 'Galéria';

  @override
  String get adminQuoteRandom => 'Véletlenszerű';

  @override
  String get adminQuoteTitleLabel => 'Cím (pl. Tanulási szünet)';

  @override
  String get adminQuoteTextLabel => 'Idézet szövege';

  @override
  String get adminAuthorOptional => 'Szerző (opcionális)';

  @override
  String get adminQuoteUpdated => 'Idézet sikeresen frissítve';

  @override
  String get adminNoQuotesFound =>
      'Nem található idézet. Adj hozzá párat a kezdéshez!';

  @override
  String get adminMotivationalLibrary => 'Motivációs tartalom és könyvtár';

  @override
  String get adminQuestionBank => 'Kérdésbank kezelése';

  @override
  String get adminSearchQuestions => 'Keresés a kérdések vagy témák között...';

  @override
  String get adminAllTypes => 'Összes típus';

  @override
  String get adminSingleChoice => 'Egyszeri választás';

  @override
  String get adminMultipleChoice => 'Többszörös választás';

  @override
  String get adminTrueFalse => 'Igaz/Hamis';

  @override
  String get adminMatching => 'Párosítás';

  @override
  String get relationAnswerA =>
      'Mindkét állítás igaz, és van köztük ok-okozati összefüggés.';

  @override
  String get relationAnswerB =>
      'Mindkét állítás igaz, de nincs köztük ok-okozati összefüggés.';

  @override
  String get relationAnswerC => 'Csak az első állítás igaz.';

  @override
  String get relationAnswerD => 'Csak a második állítás igaz.';

  @override
  String get relationAnswerE => 'Mindkét állítás hamis.';

  @override
  String get quizIncompleteQuestion => 'A kérdés hiányos.';

  @override
  String get adminRelational => 'Relációs analízis';

  @override
  String get adminLevel => 'Szint';

  @override
  String get adminAllLevels => 'Összes szint';

  @override
  String get adminAllSections => 'Összes szakasz';

  @override
  String get adminUnnamedSection => 'Névtelen szakasz';

  @override
  String get adminManageSections => 'Szakaszok kezelése';

  @override
  String get adminBatchUpload => 'Kötegelt feltöltés';

  @override
  String get adminNewEcg => 'Új EKG';

  @override
  String get adminNewQuestion => 'Új kérdés';

  @override
  String get adminTableQuestionText => 'Kérdés szövege';

  @override
  String get adminTableBloom => 'Bloom-szint';

  @override
  String get adminTableAttempts => 'Próbálkozások';

  @override
  String get adminTableAccuracy => 'Pontosság';

  @override
  String get adminTableId => 'ID';

  @override
  String get adminTableImage => 'Kép';

  @override
  String get adminTableDiagnosis => 'Diagnózis';

  @override
  String get adminTableDifficulty => 'Nehézség';

  @override
  String get adminQuestionDetails => 'Kérdés részletei';

  @override
  String get adminUnknown => 'Ismeretlen';

  @override
  String get adminAnswerKeyUnresolved => 'A helyes válasz nem azonosítható';

  @override
  String get adminUntitled => 'Névtelen';

  @override
  String get adminSubjectFallback => 'Tantárgy';

  @override
  String get adminSectionFallback => 'Szekció';

  @override
  String get adminExit => 'Kilépés';

  @override
  String get adminGoToGame => 'VISSZA A JÁTÉKHOZ';

  @override
  String get themeLight => 'Világos';

  @override
  String get themeDark => 'Sötét';

  @override
  String get adminEcgTemplateApplied =>
      'Sablon alkalmazva! Az automatikusan kitöltött mezők kiemelve.';

  @override
  String get adminEcgDifficulty => 'Nehézség';

  @override
  String get adminEcgPrimaryDiagnosis => 'Elsődleges diagnózis';

  @override
  String get adminEcgSecondaryDiagnoses => 'Másodlagos diagnózisok';

  @override
  String get adminEcgPatientHistory => '0. Betegkórtörténet (Opcionális)';

  @override
  String get adminEcgSignalmentHistory => 'Beteg adatai / Kórtörténet';

  @override
  String get adminEcgHistoryHint => 'pl. 55 ffi, mellkasi fájdalom 2 órája...';

  @override
  String get adminEcgRhythm => '1. Ritmus';

  @override
  String get adminEcgRegularity => 'Regularitás';

  @override
  String get adminEcgRatio => 'Arány';

  @override
  String get adminEcgSinusRhythm => 'Sinus ritmus?';

  @override
  String get adminEcgSinusHint => 'P a QRS előtt, pozitív a II-ben';

  @override
  String get adminEcgHeartRate => '2. Szívfrekvencia';

  @override
  String get adminFirstStatement => 'Első állítás';

  @override
  String get adminSecondStatement => 'Második állítás';

  @override
  String get adminLinkWord => 'Kötőszó';

  @override
  String get adminTranslationDraftChanged =>
      'Fordítás közben módosult a szöveg. Az új változathoz indítsd el újra a fordítást.';

  @override
  String adminEcgCaseCount(int count) {
    return '$count EKG-eset';
  }

  @override
  String adminQuestionCount(int count) {
    return '$count kérdés';
  }

  @override
  String get adminEcgLoadFailed => 'Nem sikerült betölteni az EKG-eseteket.';

  @override
  String get adminEcgSaveFailed => 'Nem sikerült menteni az EKG-esetet.';

  @override
  String get adminEcgDiagnosesLoadFailed =>
      'Nem sikerült betölteni a diagnózisokat.';

  @override
  String get adminEcgInvalidRate => 'A pulzusszám pozitív egész szám legyen.';

  @override
  String get adminEcgBpm => 'Szívfrekvencia (BPM)';

  @override
  String get adminEcgRateHint => 'A hallgatók +/- 5 BPM tűréshatárt kapnak';

  @override
  String get adminEcgConduction => '3. Vezetés';

  @override
  String get adminEcgPrInterval => 'PR intervallum';

  @override
  String get adminEcgQrsWidth => 'QRS szélesség';

  @override
  String get adminEcgQtInterval => 'QT intervallum';

  @override
  String get adminEcgAvBlock => 'AV-blokk';

  @override
  String get adminEcgSaBlock => 'SA-blokk';

  @override
  String get adminEcgBbb => 'Tawara-szár-blokk';

  @override
  String get adminEcgAxis => '4. Tengelyállás';

  @override
  String get adminEcgHeartAxis => 'Szívtengely';

  @override
  String get adminEcgPwaveMorph => '5. P-hullám morfológia';

  @override
  String get adminEcgMorphology => 'Morfológia';

  @override
  String get adminEcgAtrialEnlargement => 'Pitvari megnagyobbodás';

  @override
  String get adminEcgQrsMorph => '6. QRS morfológia';

  @override
  String get adminEcgHypertrophy => 'Hipertrófia';

  @override
  String get adminEcgPathQWaves => 'Patológiás Q-hullámok';

  @override
  String get adminEcgStTMorph => '7. ST-T morfológia';

  @override
  String get adminEcgIschemia => 'Iszkémia/Infarktus';

  @override
  String get adminEcgTWave => 'T-hullám';

  @override
  String get adminEcgIncludeManagement =>
      'Tartalmazza a +2. lépést: Kezelés és Sürgősség?';

  @override
  String get adminEcgIntermediateAdvancedOnly =>
      'Csak középhaladó/haladó eseteknél';

  @override
  String get adminEcgUrgencyLevel => 'Sürgősségi szint';

  @override
  String get adminEcgNotesNextSteps => 'Megjegyzések / Következő lépések';

  @override
  String get adminEcgManagementHint =>
      'pl. Kardiológiai konzílium, Béta-blokkoló indítása';

  @override
  String get adminEcgClickToUpload => 'Kattints az EKG csík feltöltéséhez';

  @override
  String get adminEcgAddSecondaryDiagnosis => 'Másodlagos diagnózis hozzáadása';

  @override
  String get adminEcgSaveCase => '7+2 eset mentése';

  @override
  String get adminEcgNoneTapToAdd => 'Nincs (Kattints a hozzáadáshoz)';

  @override
  String get adminEcgRegular => 'Reguláris';

  @override
  String get adminEcgIrregular => 'Irreguláris';

  @override
  String get adminEcgIrregularlyIrregular => 'Abszolút irreguláris';

  @override
  String get adminEcgNormal => 'Normál';

  @override
  String get adminEcgProlonged => 'Megnyúlt';

  @override
  String get adminEcgShort => 'Rövid';

  @override
  String get adminEcgNone => 'Nincs';

  @override
  String get adminEcgDifficultyBeginner => 'Kezdő';

  @override
  String get adminEcgDifficultyIntermediate => 'Középhaladó';

  @override
  String get adminEcgDifficultyAdvanced => 'Haladó';

  @override
  String get adminExplanationLabel => 'Magyarázat';

  @override
  String get adminOptionsSelectCorrect =>
      'Opciók (Válaszd ki az összes helyeset)';

  @override
  String adminOptionIndex(Object index) {
    return '$index. opció';
  }

  @override
  String get adminAddOption => 'Opció hozzáadása';

  @override
  String get adminSetCorrectLogic => 'Helyes logika beállítása';

  @override
  String get adminCommonKnowledgeGap => 'Gyakori tudáshiány';

  @override
  String get adminHighFailureRateWarning =>
      'Magas hibaarány észlelhető. Érdemes lehet felülvizsgálni a megfogalmazást.';

  @override
  String get adminCommonlyConfusedWith => 'GYAKRAN ÖSSZETÉVESZTVE:';

  @override
  String adminConfirmDeleteQuestion(Object id) {
    return 'Biztosan törölni szeretnéd a(z) #$id. kérdést? Ez nem vonható vissza, ha a hallgatók már válaszoltak rá.';
  }

  @override
  String get adminErrorQuestionDeleteLinked =>
      'Nem törölhető: A kérdéshez már tartoznak válaszok.';

  @override
  String adminConfirmDeleteECG(Object id) {
    return 'Biztosan törölni szeretnéd a(z) #$id. EKG esetet?';
  }

  @override
  String get adminErrorDeleteFailed => 'Törlés sikertelen';

  @override
  String get adminStatement1True => '1. állítás IGAZ';

  @override
  String get adminStatement2True => '2. állítás IGAZ';

  @override
  String get adminConnectionExists =>
      'Kapcsolat / Összefüggés létezik (Mert...)';

  @override
  String get adminMatchingPairs => '1-az-1-hez párosítás';

  @override
  String get adminAddPair => 'Pár hozzáadása';

  @override
  String adminLeftLabel(Object index) {
    return 'Bal $index';
  }

  @override
  String adminRightLabel(Object index) {
    return 'Jobb $index';
  }

  @override
  String get adminRenameSection => 'Szekció átnevezése';

  @override
  String get adminTrue => 'IGAZ';

  @override
  String get adminFalse => 'HAMIS';

  @override
  String adminTranslationFailed(Object error) {
    return 'Fordítás sikertelen: $error';
  }

  @override
  String get adminSourceFieldEmpty => 'A forrásmező üres!';

  @override
  String get adminSaveQuestion => 'Kérdés mentése';

  @override
  String get adminErrorQuestionSaveFailed => 'Kérdés mentése sikertelen';

  @override
  String get adminSearchCommandsHint =>
      'Keresés a parancsok között (@user, #kérdés)...';

  @override
  String get adminKeyboardShortcuts => 'Gyorsbillentyűk';

  @override
  String get adminNavigate => 'Navigáció';

  @override
  String get adminSelect => 'Kiválasztás';

  @override
  String get adminClose => 'Bezárás';

  @override
  String get adminPowerCenter => 'Admin Power Center';

  @override
  String get adminNoMatchingCommands => 'Nincs találat';

  @override
  String get adminCommandGoToDashboard => 'Irány a vezérlőpult';

  @override
  String get adminCommandGoToQuestions => 'Irány a kérdések';

  @override
  String get adminCommandGoToUsers => 'Irány a felhasználók';

  @override
  String get adminCommandGoToQuotes => 'Irány az idézetek';

  @override
  String get adminCommandExitAdmin => 'Kilépés az adminból';

  @override
  String get adminJumpToUser => 'UGRÁS A FELHASZNÁLÓHOZ';

  @override
  String get adminJumpToQuestion => 'UGRÁS A KÉRDÉSHEZ';

  @override
  String get adminF10Help => 'F10 segítség';

  @override
  String get adminBackToCommands => 'Vissza a parancsokhoz';

  @override
  String get adminShowing => 'Megjelenítve:';

  @override
  String get adminVersion => 'verzió';

  @override
  String get adminQuestionType => 'Kérdés típusa';

  @override
  String get adminBloomCriteria => 'Bloom kritérium';

  @override
  String get adminSubject => 'Tárgy';

  @override
  String get adminSection => 'Szekció';

  @override
  String get adminErrorSelectSubject => 'Kérjük, válassz egy tárgyat';

  @override
  String get adminErrorSelectSection => 'Kérjük, válassz egy szekciót';

  @override
  String get adminAutoFill => 'Automatikus kitöltés';

  @override
  String get adminEnglish => 'Angol';

  @override
  String get adminHungarian => 'Magyar';

  @override
  String get adminSelectQuestion => 'Válassz kérdést';

  @override
  String get adminDifficultyShort => 'Neh.';

  @override
  String get adminAddQuestion => 'Kérdés hozzáadása';

  @override
  String get adminEditQuestion => 'Kérdés szerkesztése';

  @override
  String get adminQuestionBankTitle => 'Kérdésbank kezelése';

  @override
  String get adminQuestionsSmall => 'Kérdések';

  @override
  String get adminManageSectionsTooltip => 'Szekciók kezelése';

  @override
  String get adminBatchUploadTooltip => 'Tömeges feltöltés';

  @override
  String get adminNewECG => 'Új EKG';

  @override
  String get adminQuotesLoadFailed => 'Nem sikerült betölteni az idézeteket.';

  @override
  String get adminQuoteSaveFailed => 'Nem sikerült menteni az idézetet.';

  @override
  String get adminQuestionReports => 'Kérdéshez érkezett hibajelzések';

  @override
  String get adminReportsLoadFailed =>
      'A kérdéshez tartozó hibajelzéseket nem sikerült betölteni.';

  @override
  String get adminReportsEmpty =>
      'Ehhez a kérdéshez még nem érkezett hibajelzés.';

  @override
  String get adminIgnoreReport => 'Elvetés';

  @override
  String get adminResolveReport => 'Lezárás';

  @override
  String get adminReportUpdated => 'Hibajelzés frissítve.';

  @override
  String get adminReportUpdateFailed =>
      'A hibajelzést nem sikerült frissíteni.';

  @override
  String get adminBroadcastFailed =>
      'A kézbesítést nem sikerült megerősíteni. Az üzenet újraküldhető.';

  @override
  String adminBroadcastDelivered(int count) {
    return 'A közleményt ennyi hallgató postaládájába kézbesítettük: $count';
  }

  @override
  String get adminExportFailed => 'Nem sikerült menteni a jelentést.';

  @override
  String get adminExportUnavailable => 'Nincs exportálható kérdésstatisztika.';

  @override
  String get adminNotificationBroadcastTitle => 'Közlemény küldése';

  @override
  String get adminNotificationBroadcastDesc =>
      'A közleményt minden hallgató az alkalmazáson belüli postaládájában kapja meg.';

  @override
  String get adminNotificationLabelTitle => 'Értesítés címe';

  @override
  String get adminNotificationLabelMessage => 'Üzenet szövege';

  @override
  String get adminNotificationHintTitle => 'pl. Új patológia kvíz érhető el!';

  @override
  String get adminNotificationHintMessage => 'Írd be az értesítés tartalmát...';

  @override
  String get adminNoEcgCasesFound => 'Nem található EKG eset.';

  @override
  String get adminNoDataAvailable => 'Nincs elérhető adat.';

  @override
  String get adminItems => 'elem';

  @override
  String get adminSuccessQuestionsMoved => 'A kérdések sikeresen áthelyezve';

  @override
  String get adminErrorMoveQuestions => 'A kérdések áthelyezése sikertelen';

  @override
  String get adminYesDeleteEverything => 'IGEN, TÖRÖLJ MINDENT';

  @override
  String get adminNoAnalyticsAvailable => 'Nincs elérhető analitika';

  @override
  String get adminNeedsAttention => 'Figyelmet igényel:';

  @override
  String get adminLivePreview => 'ÉLŐ ELŐNÉZET';

  @override
  String get adminSendNow => 'Küldés most';

  @override
  String get adminErrorFillAllFields => 'Kérjük, tölts ki minden mezőt';

  @override
  String get adminSuccessNotificationSent => 'Az értesítés sikeresen elküldve!';

  @override
  String get adminSelectAnItem => 'Válassz egy elemet';

  @override
  String get adminTableType => 'Típus';

  @override
  String get adminTableSection => 'Szekció';

  @override
  String get adminBatchUploadTitle => 'Kérdések tömeges feltöltése';

  @override
  String get adminBatchUploadSubtitle =>
      'Tölts fel Excel (.xlsx) vagy CSV fájlt több kérdés egyszerre történő hozzáadásához.';

  @override
  String get adminPreparationLabel => 'Előkészület:';

  @override
  String get adminPreparationSubtitle =>
      'Használd a sablonunkat a helyes formázás és legördülő menük biztosításához.';

  @override
  String get adminDownloadTemplate => 'Excel sablon letöltése';

  @override
  String get adminChooseFile => 'Fájl kiválasztása és feltöltés';

  @override
  String get adminErrorReadBytes => 'Nem sikerült beolvasni a fájlt.';

  @override
  String get adminProcessingUpload => 'Feltöltés feldolgozása';

  @override
  String get adminUploadFailed => 'Feltöltés sikertelen';

  @override
  String get adminImportFileTooLarge =>
      'Legfeljebb 5 MiB méretű fájlt válassz.';

  @override
  String get adminImportWithErrors => 'Az importálás hibákkal fejeződött be';

  @override
  String get adminUploadComplete => 'Feltöltés kész';

  @override
  String get adminParsing => 'Feldolgozás:';

  @override
  String adminUploadSuccess(Object count) {
    return '$count kérdés sikeresen feltöltve.';
  }

  @override
  String adminItemsSelected(Object count) {
    return '$count elem kiválasztva';
  }

  @override
  String get adminClearSelection => 'Kiválasztás törlése';

  @override
  String get adminMoveTo => 'Áthelyezés';

  @override
  String get adminDeleteBatch => 'Köteg törlése';

  @override
  String get adminConfirmBatchDelete => 'Törlés megerősítése';

  @override
  String adminConfirmBatchDeleteSubtitle(Object count) {
    return 'Biztosan törölni szeretnél $count kérdést? Ez nem vonható vissza, ha még nincsenek rájuk válaszok.';
  }

  @override
  String get adminDeleteAll => 'Összes törlése';

  @override
  String adminSuccessDeletedCount(Object count) {
    return '$count kérdés törölve';
  }

  @override
  String get adminErrorDeleteBulk =>
      'Törlés sikertelen (néhány kérdésnek lehetnek válaszai)';

  @override
  String get adminMoveQuestionsTitle => 'Kérdések áthelyezése témakörbe';

  @override
  String adminMoveQuestionsSubtitle(Object count) {
    return 'Válassz cél témakört $count kérdéshez:';
  }

  @override
  String get adminTargetTopic => 'Cél témakör';

  @override
  String get adminMoveNow => 'Áthelyezés most';

  @override
  String get adminErrorSectionNameEmpty =>
      'Az angol szekció neve nem lehet üres';

  @override
  String get adminSuccessSectionCreated => 'Szekció sikeresen létrehozva';

  @override
  String get adminErrorSectionCreateFailed => 'Szekció létrehozása sikertelen';

  @override
  String get adminDeleteSectionTitle => 'Szekció törlése';

  @override
  String adminConfirmDeleteSection(Object name) {
    return 'Biztosan törölni szeretnéd a(z) \'$name\' szekciót?';
  }

  @override
  String get adminConfirmDataLossTitle => 'Adatvesztés megerősítése';

  @override
  String get adminDeleteSectionWarning =>
      'A szekció törlése VÉGLEGESEN törli a benne lévő összes kérdést. Ez a művelet nem vonható vissza.';

  @override
  String get adminConfirmAction => 'Teljesen biztos vagy benne?';

  @override
  String get adminSuccessSectionDeleted => 'Szekció sikeresen törölve';

  @override
  String get adminManageSectionsTitle => 'Szekciók kezelése';

  @override
  String get adminSectionNameEnLabel => 'Szekció neve (EN)';

  @override
  String get adminSectionNameHuLabel => 'Szekció neve (HU)';

  @override
  String get adminAddSection => 'Szekció hozzáadása';

  @override
  String get adminExistingSections => 'Létező szekciók';

  @override
  String get adminNoSectionsYet =>
      'Még nincsenek szekciók. Hozz létre egyet fent!';

  @override
  String adminRenameSectionLabel(Object lang) {
    return 'Szekció átnevezése ($lang)';
  }

  @override
  String get adminQuotesSubtitle => 'Motivációs idézetek és galéria kezelése';

  @override
  String get adminManageIcons => 'Ikonok kezelése';

  @override
  String get adminEcgSelectDiagnosis =>
      'Kérjük, válassz egy elsődleges diagnózist';

  @override
  String get adminEcgUploadImage => 'Kérjük, tölts fel egy EKG csíkot';

  @override
  String get adminEcgUploadFailed => 'A kép feltöltése sikertelen';

  @override
  String get adminEcgNewCase => 'Új 7+2 EKG eset';

  @override
  String get adminEcgEditCase => '7+2 eset szerkesztése';

  @override
  String get adminRequired => 'A mező kitöltése kötelező';

  @override
  String get quizTypeSingleChoice => 'Egyszeri választás';

  @override
  String get quizTypeMultipleChoice => 'Többszörös választás';

  @override
  String get quizTypeTrueFalse => 'Igaz/Hamis';

  @override
  String get quizTypeMatching => 'Párosítás';

  @override
  String get quizTypeRelational => 'Relációs analízis';

  @override
  String get done => 'Kész';

  @override
  String get close => 'Bezárás';

  @override
  String get verifyEmailTitle => 'E-mail-cím megerősítése';

  @override
  String get verificationRequired => 'Megerősítés szükséges';

  @override
  String verificationSentTo(String email) {
    return 'Erre a címre küldtük a hatjegyű ellenőrzőkódot:\n$email';
  }

  @override
  String get verificationEnterCode => 'Add meg a hatjegyű kódot';

  @override
  String get verificationContinue => 'Megerősítés és folytatás';

  @override
  String get verificationResend => 'Kód újraküldése';

  @override
  String get verificationSuccess => 'Az e-mail-címedet megerősítettük.';

  @override
  String get verificationResent => 'Új ellenőrzőkódot küldtünk.';

  @override
  String get verificationRetry => 'A kérés nem sikerült. Próbáld újra.';

  @override
  String get verificationRestart => 'Újrakezdés';

  @override
  String get verificationWait => 'Túl sok kérés. Próbáld újra később.';

  @override
  String get verificationUnavailable =>
      'A megerősítés átmenetileg nem érhető el. Próbáld újra később.';

  @override
  String get verificationChanged =>
      'Ez a megerősítési kérés megváltozott. Kezdd újra.';

  @override
  String get verificationSignOutFailed =>
      'A kijelentkezés nem fejeződött be ezen az eszközön. Próbáld újra.';

  @override
  String get duelSelectWager => 'Tét kiválasztása';

  @override
  String get duelChooseWager => 'Válaszd ki a párbaj tétjét.';

  @override
  String get duelFindMatch => 'Ellenfél keresése';

  @override
  String get duelSearching => 'Ellenfél keresése…';

  @override
  String duelWagerAmount(int amount) {
    return 'Tét: $amount 🩺';
  }

  @override
  String duelWalletAmount(int amount) {
    return '$amount sztetoszkóp';
  }

  @override
  String get duelLowBalance => 'Ehhez a téthez nincs elegendő egyenleged.';

  @override
  String get duelRefreshFailed =>
      'Az egyenleg frissítése nem sikerült. Próbáld újra.';

  @override
  String get duelLeaveFailed =>
      'A kilépést nem sikerült megerősíteni. Próbáld újra.';

  @override
  String get profileRefreshRetry => 'A profil frissítése sikertelen. Újra';

  @override
  String get nicknameLength => 'Adj meg egy 1–255 karakteres becenevet.';

  @override
  String get nicknameSaveFailed =>
      'A becenév mentése sikertelen. Próbáld újra.';

  @override
  String get profileSessionChanged =>
      'Az aktív fiók megváltozott. Zárd be a szerkesztőt.';

  @override
  String get roundsTitle => 'Napi klinikai vizit';

  @override
  String get roundsConfirmed => 'A mai vizitet teljesítetted.';

  @override
  String roundsRequirement(int goal) {
    return 'A vizithez adj $goal helyes választ az UTC szerinti napon.';
  }

  @override
  String roundsProgressCount(int progress, int goal) {
    return '$progress / $goal helyes válasz';
  }

  @override
  String get roundsPractice => 'Gyakorlás indítása';

  @override
  String get roundsConfirm => 'Napi vizit jóváírása';

  @override
  String get roundsRetry => 'A vizit állapota nem ellenőrizhető. Újra';

  @override
  String roundsStrikes(int count) {
    return 'Figyelmeztetések száma: $count';
  }

  @override
  String get roundsProbation => 'Klinikai próbaidő';

  @override
  String roundsSubjectStats(int count, int percent) {
    return 'Tantárgyi válaszok száma: $count · $percent% helyes';
  }

  @override
  String get roundsNoResponses => 'Még nincs rögzített tantárgyi válasz.';

  @override
  String get roundsSummaryRetry =>
      'A tantárgyi eredmények betöltése sikertelen. Újra';

  @override
  String get roundsRefresh => 'Haladás frissítése';

  @override
  String get quizFallbackQuote => 'Tiszta fejjel könnyebb a célra figyelni.';

  @override
  String get quizPracticeSubject => 'Gyakorlás a tantárgyból';

  @override
  String get quizSectionsRetry => 'A témaköröket nem sikerült betölteni. Újra';

  @override
  String get quizNoQuestions => 'Még nincs aktív kérdés';

  @override
  String get quizReviewTitle => 'Okos ismétlés';

  @override
  String get quizReadinessRetry =>
      'A felkészültséget nem sikerült betölteni. Újra';

  @override
  String get quizNoReadiness =>
      'Az első kvíz után itt láthatod a felkészültségedet.';

  @override
  String quizReadyPercent(int score) {
    return 'Felkészültség $score%';
  }

  @override
  String get quizRecommendations => 'Ismétlésre javasolt témák';

  @override
  String get quizReviewRetry => 'A javaslatokat nem sikerült betölteni. Újra';

  @override
  String get quizReviewEmpty => 'Most nincs ismétlésre javasolt téma.';

  @override
  String quizRetention(int percent) {
    return 'Becsült tudásmegtartás $percent%';
  }

  @override
  String quizDaysSince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days napja gyakoroltad',
      one: 'Egy napja',
      zero: 'Kevesebb mint egy napja',
    );
    return '$_temp0';
  }

  @override
  String get quizReviewSessionEnded =>
      'Ez az ismétlés az előző bejelentkezéshez tartozott.';
}
