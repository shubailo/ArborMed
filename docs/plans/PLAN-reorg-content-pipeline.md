# Plan: Content Pipeline Reorganization (Option B)

## 1. Goal
Restructure the codebase to separate the "Question Factory" (generation, translation, upload) from the "App Backend" (API), and introduce code quality tools.

## 2. New Directory Structure

```
/
├── backend/                # Express API (remains mostly as is)
│   ├── src/
│   ├── package.json
│   └── .eslintrc.json      # [NEW] Linting config
├── mobile/                 # Flutter App
├── content-engine/         # [NEW] The "Factory"
│   ├── src/                # Scripts moved here
│   │   ├── generator/      # generate_questions.js
│   │   ├── translator/     # translate_questions.js
│   │   └── uploader/       # upload_questions.js
│   ├── data/               # Staging (was questions/pending)
│   └── package.json        # [NEW] Separate dependencies for tools
├── docs/                   # Documentation
│   ├── assets/             # Images (arbormed.png)
│   └── plans/              # PLAN-*.md files
└── tools/                  # Shared dev tooling (optional)
```

## 3. Execution Tasks

### Phase 1: Content Engine Setup
1.  **Create Directory**: `mkdir content-engine`
2.  **Initialize**: `npm init -y` in `content-engine`.
3.  **Move Scripts**:
    - `scripts/*` -> `content-engine/src/processing/`
    - `backend/scripts/generate_questions.js` -> `content-engine/src/generation/`
    - `backend/scripts/upload_*.js` -> `content-engine/src/upload/`
    - *Note*: `test_smtp.js` moves to `backend/test/` (create if needed).
4.  **Migrate Dependencies**:
    - Move script-specific deps (`google-translate-api-x`, `pdf-parse`, `openai`?) from `backend/package.json` to `content-engine/package.json`.
5.  **Fix Imports**: Update `require('../../src/config/db')` paths to point to a shared config or relative path.

### Phase 2: Root Cleanup
1.  **Move Docs**: `PLAN-*.md` -> `docs/plans/`.
2.  **Move Assets**: `arbormed.png` -> `docs/assets/`.
3.  **Delete Empty**: `scripts/`, `questions/`, `backend/scripts/`.

### Phase 3: Code Quality (Linting)
1.  **Backend**:
    - Install `eslint`, `prettier`, `eslint-config-prettier`.
    - Initialize `.eslintrc.json`.
    - Add `npm run lint` script.
2.  **Content Engine**:
    - (Optional) Add basic linting here too.

## 4. Risks & Mitigation
- **Risk**: Breaking script database connections.
  - **Mitigation**: Create a `content-engine/src/db-config.js` that loads `.env` correctly.
- **Risk**: `nodemon` or start scripts failing.
  - **Mitigation**: Verify `backend/package.json` scripts still work after moving files.

## 5. Next Steps
Run `/create` to execute this plan.
