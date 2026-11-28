# ArborMed

ArborMed is a bilingual medical education app. Students practise clinical questions and ECG interpretation, earn coins, and compete in timed duels. The Flutter app uses Drift for local storage. Express, Socket.IO and PostgreSQL handle accounts, grading, progression and balances.

![ArborMed login and study app](docs/images/banner.png)

## Student experience

- **Practice and review.** Students answer clinical questions in Hungarian or English. The server selects due reviews and new questions, grades submissions, and updates Bloom progression. The mastery score weights levels 1–2 once and higher levels twice. The app keeps pending answers locally and synchronizes them when the service is reachable.
- **ECG interpretation.** Students work through the case and submit their diagnoses before receiving the marking rubric. The detailed report compares each observation with the case findings.
- **Clinic and shop.** Study rewards fund items for the student's clinic. Catalog updates preserve the student's inventory. Crate clients can provide a unique `purchaseId` and reuse it when retrying the same opening. Legacy openings without a key remain independent purchases.
- **Timed duels.** Matched students receive the same questions. The server reserves the stakes, scores the match and settles the balance. A draw returns both stakes.

## Run locally

Use Node.js 24, npm, Flutter 3.38.9 and PostgreSQL. The backend expects a database with the ArborMed schema. An existing installation or a verified schema backup is needed for the historical baseline.

1. From `services/backend`, run `npm ci`.
2. Create `services/backend/.env` with `NODE_ENV=development`, `DATABASE_URL`, and a randomly generated `JWT_SECRET`. Point local development at a separate database. Set up a mail provider for registration and recovery. The backend supports SMTP with `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, or Resend with its API key in `SMTP_PASS` and a verified `VERIFIED_SENDER`. Google sign-in requires `GOOGLE_CLIENT_ID`.
3. Prepare the database as described below, then run `npm run dev`. The default port is 3000. `/ping` checks the process and `/health` checks database readiness.
4. From `apps/student_app`, run `flutter pub get --enforce-lockfile` and `flutter run -d chrome`. To choose a backend, pass `--dart-define=API_URL=https://your-backend.example` to Flutter.

## Database migrations

`services/backend/migrations` is the migration directory. Files through version 050, unnumbered scripts and the files under `legacy-variants/` preserve the historical SQL. Some used provider-specific roles or extensions, multiple files shared version numbers, and some depended on changes made outside Git.

Before the first upgrade, take a backup and compare a restored copy with the schema used by the running application. Run the following as the schema owner. A PostgreSQL transaction pooler cannot hold a session advisory lock across files. Set `MIGRATION_DATABASE_URL` to a direct or session-mode connection when the app uses a transaction pooler.

```sh
cd services/backend
npm run migrate -- --baseline
npm run migrate
```

The first command checks core columns and records the operator's baseline. It does not reconstruct or certify historical data. The second applies new numbered files under a lock and records each checksum in the same transaction as its SQL. Subsequent releases use `npm run migrate`. To initialise an empty database, restore a verified ArborMed baseline first. Create future migrations with unique numbers and transactional SQL.

Migration 066 repairs unambiguous historical answer keys and marks unresolved questions inactive. It matches the original bilingual prompt, options, content, type and answer so locally edited records are preserved. The repository corpus currently has 3,816 active questions and 213 awaiting editorial review.

The readiness check returns HTTP 503 while an expected migration is missing or its recorded checksum differs. Migration 067 gives the backend roles `med_buddy_app` and `service_role` read access to applied filenames. Migration 069 also grants access to the checksum. Deployments with a custom runtime role need SELECT on both filename and checksum and a SELECT policy on `arbormed_schema_migrations`.

Run `npm run migrate -- --check` from the backend directory with the target release and its runtime `DATABASE_URL`. The command reads the migration ledger and reports missing files and mismatched checksums. The backend logs the same diagnostics privately when readiness fails.

## Deployment

- Backend database connections verify the TLS certificate. For a private CA, supply its PEM in `DB_CA_CERT`. In development a local PostgreSQL server may use a loopback connection.
- Configure `SUPER_ADMIN_USER_ID` with the existing administrator?s numeric account ID to enable administrator demotion, deletion and subject assignment. Installations using `SUPER_ADMIN_EMAIL` can retain their configured address until they set the ID. The ID takes precedence.
- Set `ALLOWED_ORIGINS` to a comma-separated list of exact additional web origins. Native clients can omit the Origin header. The ArborMed Netlify production origin is included.
- Set `SUPER_ADMIN_USER_ID` to the existing admin account that manages administrators and subject assignments. Installations using a configured `SUPER_ADMIN_EMAIL` can continue using that setting until they switch to the stable user ID.
- New production image uploads use a public, read-only-for-visitors Supabase Storage bucket. Set `SUPABASE_URL`, `SUPABASE_UPLOAD_BUCKET` and the backend-only `SUPABASE_SERVICE_ROLE_KEY`. Existing image URLs still resolve from `services/backend/uploads/`. Back up any images held only on a running host before replacing it. The repository cannot recover an ephemeral host's files.
- Netlify builds the web app from the checked-out Dart sources with `bash scripts/build_web.sh`. Set `API_URL` and any web Firebase configuration in the build environment. The script passes supported values to Flutter. The SQLite WASM module and Drift worker under `apps/student_app/web` must match the versions in `pubspec.lock`.
- For this upgrade, migrate first and release the backend and student app together. Verify registration mail, reset mail, image upload and a quiz submission on staging. Accounts previously marked verified during shortcut registration cannot be identified by the verification flag alone.
- A historical migration contained a fixed login password for the backend database role. If it was used, rotate the role credential at the database provider and update the deployment secret.

## Checks

```sh
cd services/backend
npm run lint
npm test
npm audit --omit=dev --audit-level=high
```

For database integration tests, set `TEST_DATABASE_URL` and `DUEL_TEST_DATABASE_URL` to a disposable PostgreSQL database. The GitHub Actions workflow provisions one. Run `flutter analyze`, `flutter test` and `flutter build web --release` from `apps/student_app` to check the student app.

## Source guide

- [Student features](apps/student_app/lib/features/) and [local database](apps/student_app/lib/database/)
- [Backend controllers](services/backend/src/controllers/), [question types](services/backend/src/services/questionTypes/) and [progression engine](services/backend/src/services/pedagogicalEngine.js)
- [Project documentation](docs/) and [content tooling](tools/)
- [Pathophysiology source materials](content-engine/sources/pathophysiology/), [room artwork sources](design-system/assets/room-source/) and the [archived interface audit](docs/archive/ui-ux/)

The optional ECG extractor takes a casebook PDF and a new output directory, for example `python tools/extract_150_ecg.py casebook.pdf review-output` with PyMuPDF installed. Review its proposed cases and SQL before including them in a new numbered migration.
