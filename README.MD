# ArborMed

ArborMed is a bilingual medical education app. Students practise clinical questions and ECG interpretation, earn coins, and compete in timed duels. The Flutter app uses Drift for local storage. Express, Socket.IO and PostgreSQL handle accounts, grading, progression and balances.

![ArborMed login and study app](docs/images/banner.png)

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

## Deployment

- Backend database connections verify the TLS certificate. For a private CA, supply its PEM in `DB_CA_CERT`. In development a local PostgreSQL server may use a loopback connection.
- Set `ALLOWED_ORIGINS` to a comma-separated list of exact additional web origins. Native clients can omit the Origin header. The ArborMed Netlify production origin is included.
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
