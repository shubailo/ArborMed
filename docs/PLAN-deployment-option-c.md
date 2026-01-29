# Plan: Deployment Option C (Render + Supabase + APK)

## 1. Overview
This plan focuses on a "Free Start" deployment strategy. We will migrate the local Node.js/PostgreSQL backend to cloud hosting (Render & Supabase) and build a release APK for Android distribution. This allows external users to register and use the app without incurring hosting costs.

## 2. Project Type
**HYBRID (Mobile + Backend)**
- **Mobile**: Flutter Android App
- **Backend**: Node.js/Express API

## 3. Success Criteria
1.  **Database**: Production PostgreSQL instance running on Supabase.
2.  **Backend**: API accessible at a public `https://...onrender.com` URL.
3.  **Connectivity**: Mobile app successfully logs in/registers via the public URL.
4.  **Artifact**: `app-release.apk` generated and installable on a generic Android device.

## 4. Tech Stack
| Component | Technology | Rationale |
| :--- | :--- | :--- |
| **Backend** | Render (Web Service) | Free tier, supports Node.js, native SSL. |
| **Database** | Supabase | Free tier, high-performance PostgreSQL. |
| **Mobile** | Flutter | Existing codebase, easy APK generation. |

## 5. Task Breakdown

### Phase 1: Database Migration (Supabase)
- [ ] **Task 1.1**: Create Supabase Project
    - *Agent*: `database-architect`
    - *Input*: N/A (Manual: User needs to create account) -> **Actually, we can use a Migration Script if user provides creds, but for now we task the User to provide the Connection String.**
    - *Output*: `DATABASE_URL` environment variable.
    - *Verify*: Connection successful via pgAdmin or script.

- [ ] **Task 1.2**: Schema Migration
    - *Agent*: `backend-specialist`
    - *Input*: `src/scripts/migrate.js` + New DB URL
    - *Output*: Tables created in Supabase.
    - *Verify*: `node src/scripts/migrate.js` returns success.

### Phase 2: Backend Deployment (Render)
- [ ] **Task 2.1**: Prepare `render.yaml` (Optional) or Manual Setup
    - *Agent*: `devops-engineer`
    - *Input*: Repository URL.
    - *Output*: Service configured on Render.
    - *Verify*: Build logs show "Build Successful".

- [ ] **Task 2.2**: Environment Configuration
    - *Agent*: `devops-engineer`
    - *Input*: `DATABASE_URL`, `JWT_SECRET`, `PORT=10000` (Render default).
    - *Output*: Running Service.
    - *Verify*: `curl https://med-buddy.onrender.com/health` returns `200 OK`.

### Phase 3: Mobile Configuration
- [ ] **Task 3.1**: Update API Constants
    - *Agent*: `mobile-developer`
    - *Input*: `mobile/lib/services/api_service.dart`.
    - *Action*: Replace `localhost` with Render URL.
    - *Output*: Updated source code.
    - *Verify*: App builds without errors.

- [ ] **Task 3.2**: Android Manifest Permissions
    - *Agent*: `mobile-developer`
    - *Input*: `mobile/android/app/src/main/AndroidManifest.xml`.
    - *Action*: Ensure `INTERNET` permission is explicit (usually is).
    - *Verify*: Code review.

### Phase 4: Build & Release
- [ ] **Task 4.1**: Generate Keystore (Debug/Release)
    - *Agent*: `mobile-developer`
    - *Input*: Keytool command.
    - *Output*: `upload-keystore.jks`.
    - *Verify*: Keystore exists.

- [ ] **Task 4.2**: Build APK
    - *Agent*: `mobile-developer`
    - *Input*: `flutter build apk --release`.
    - *Output*: `build/app/outputs/flutter-apk/app-release.apk`.
    - *Verify*: File size > 15MB.

## 6. Phase X: Verification
- [ ] **Lint Check**: `flutter analyze`
- [ ] **Security Scan**: `python .agent/skills/vulnerability-scanner/scripts/security_scan.py .`
- [ ] **End-to-End Test**: Install APK on emulator, register new user, check Supabase DB.

---
**Next Step**: Run `/create` to start Phase 1.
