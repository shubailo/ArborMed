# PLAN: Flutter Web Deployment to Netlify

## Overview
This plan outlines the steps to deploy the "ArborMed" (Med Buddy) Flutter web application to Netlify. The goal is to ensure a functional web experience with proper SPA routing and production backend connectivity while maintaining local development capabilities.

- **Status**: 📝 PLANNING
- **Project Type**: WEB (Deployment Infrastructure)
- **Primary Agent**: `frontend-specialist` (handled by Antigravity)

## Success Criteria
- [ ] `_redirects` file is present in `mobile/web` and correctly copied to `build/web` during build.
- [ ] A clean build script (`build_web_clean.bat`) exists to handle asset clearing and production flags.
- [ ] The web app successfully connects to `https://med-buddy-lrri.onrender.com` when built in release mode.
- [ ] Netlify deployment is successful and accessible via a live URL.
- [ ] Refreshing a sub-page (e.g. `/login`) does not result in a Netlify 404 error.

## Tech Stack
- **Framework**: Flutter (Web)
- **Hosting**: Netlify
- **Deployment**: Netlify CLI (Node.js)
- **Backend**: Node.js/Express (Render)

## File Structure Changes
```text
mobile/
├── web/
│   └── _redirects (NEW)
└── build_web_clean.bat (NEW)
```

## Task Breakdown

### Phase 1: Configuration
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| T1 | Create `_redirects` | `frontend-specialist` | `frontend-design` | P0 | None |
| T2 | Create `build_web_clean.bat` | `frontend-specialist` | `powershell-windows` | P1 | None |

**T1 INPUT→OUTPUT→VERIFY:**
- Input: Knowledge of Netlify redirection rules.
- Output: `mobile/web/_redirects` file with `/* /index.html 200`.
- Verify: File exists in `mobile/web/`.

**T2 INPUT→OUTPUT→VERIFY:**
- Input: Flutter build commands and Windows batch syntax.
- Output: `mobile/build_web_clean.bat` script.
- Verify: Script runs and initiates `flutter build web`.

### Phase 2: Build & Verification
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| T3 | Execute Production Build | `frontend-specialist` | `clean-code` | P0 | T1, T2 |
| T4 | Verify Build Artifacts | `frontend-specialist` | `clean-code` | P0 | T3 |

**T3 INPUT→OUTPUT→VERIFY:**
- Input: Command `flutter build web --release`.
- Output: `build/web/` directory populated.
- Verify: Termination code 0.

**T4 INPUT→OUTPUT→VERIFY:**
- Input: `build/web/` directory.
- Output: Confirmation of `_redirects` and `index.html`.
- Verify: `ls build/web/_redirects` returns success.

### Phase 3: Deployment
| Task ID | Name | Agent | Skills | Priority | Dependencies |
|---------|------|-------|--------|----------|--------------|
| T5 | Deploy to Netlify | `devops-engineer` | `server-management` | P0 | T4 |

**T5 INPUT→OUTPUT→VERIFY:**
- Input: `netlify-cli`, built artifacts.
- Output: Live URL from Netlify.
- Verify: URL is active and accessible.

## Phase X: Final Verification
- [ ] Build: ✅ Success
- [ ] SPA Routing: ✅ Sub-pages refresh correctly
- [ ] Backend Connection: ✅ Production URL used in release mode
- [ ] Asset Cache: ✅ Built with a fresh state

---

[OK] Plan created: docs/PLAN-flutter-web-deploy.md

Next steps:
- Review the plan
- Run `/create` or simply confirm to start implementation
