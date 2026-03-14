## 2025-02-23 - Login Timing Attack
**Vulnerability:** The `login` function in `authController.js` had a timing side-channel. If a user was not found, it returned immediately without performing a password hash comparison, whereas valid users triggered a slow `bcrypt.compare`. This allowed enumeration of valid email addresses.
**Learning:** Even if `bcrypt` handles timing-safe comparisons internally, the application logic must ensure the comparison is actually invoked in all code paths to prevent timing differences based on user existence.
**Prevention:** Always perform a hash comparison, even if the user is not found. Use a dummy hash (valid format) for the comparison to ensure similar execution time.

## 2025-02-23 - Shop Balance Race Condition
**Vulnerability:** A "Check-Then-Act" race condition in `shopController.js` allowed users to purchase items even with insufficient balance if concurrent requests were made, because the balance check (`SELECT`) was separate from the deduction (`UPDATE`).
**Learning:** In highly concurrent systems, separate read and write operations within a transaction do not guarantee consistency unless row locks (`FOR UPDATE`) are used. Without locks, another transaction can modify the value between the read and the write.
**Prevention:** Use atomic database updates with conditional `WHERE` clauses (e.g., `UPDATE ... SET balance = balance - cost WHERE balance >= cost`) to enforce constraints directly in the database operation. Check the `rowCount` to determine if the operation succeeded.

## 2025-02-27 - Missing Authorization Checks in Admin Panel
**Vulnerability:** The `adminDeleteQuestion` and `adminBulkAction` endpoints in `adminQuestionController.js` lacked Insecure Direct Object Reference (IDOR) and role-based authorization checks, allowing any authenticated user with the 'admin' role to delete or bulk-modify questions belonging to other admins or unassigned subjects. Only `adminUpdateQuestion` correctly enforced these boundary checks.
**Learning:** Security controls applied to one endpoint (like updates) are frequently missed on counterpart endpoints (like deletes or bulk operations) within the same controller file. Defense-in-depth requires explicitly validating ownership/permissions on *every* destructive action.
**Prevention:** Ensure all state-mutating controller methods (especially destructive ones like DELETE or bulk edits) duplicate or extract the same IDOR and ownership verification logic used in singular UPDATE routes before performing their operations.

## 2024-05-24 - Missing Authorization on Uploads
**Vulnerability:** Any authenticated user could list and delete files via upload endpoints.
**Learning:** Global file management endpoints were missing role-based access control, relying only on basic authentication (protect middleware).
**Prevention:** Always apply the admin middleware to sensitive, system-wide resource management routes.
## 2024-06-05 - [Unvalidated Dynamic Sort Params in SQL]
**Vulnerability:** Dynamic SQL `ORDER BY` and `LIMIT`/`OFFSET` clauses in controllers (e.g., `adminQuestionController.js`, `adminController.js`) were susceptible to throwing unhandled 500 errors or potentially allowing unvalidated strings through, as they cannot be parameterized using standard `$1` bindings.
**Learning:** `req.query` parameters must always be treated as untrusted, especially when constructing dynamic query strings. Even if not directly exploitable for data exfiltration via SQLi, poor validation leads to DoS via application crashes (e.g., `order.toUpperCase()` on an undefined or object value) and potential resource exhaustion (e.g., arbitrarily large `LIMIT`).
**Prevention:** Strictly validate `sortBy` against a predefined mapping object (`sortMap`), sanitize `order` to strictly `'ASC'` or `'DESC'`, and securely parse `page`/`limit` using `parseInt(val, 10)` with explicit upper and lower bounds before injecting them into the query.

## 2025-05-15 - Timing Attack Mitigation in changePassword
**Vulnerability:** The `changePassword` function in `authController.js` used a short-circuiting check (`!user || !(await bcrypt.compare(...))`). If a user was not found (e.g. concurrent deletion), it would return early, bypassing the expensive `bcrypt.compare` and creating a timing side-channel.
**Learning:** Security fixes applied to one flow (like `login`) must be consistently applied to all similar flows (like `changePassword` or `verifyEmail` if it uses hashes) to ensure uniform security across the application.
**Prevention:** Always perform a hash comparison against a `DUMMY_HASH` if the user is missing, and ensure this behavior is asserted in unit tests.

## 2025-05-20 - Unbounded Multer Memory Storage
**Vulnerability:** The `/api/quiz/admin/questions/batch` endpoint used `multer.memoryStorage()` without any `fileSize` limits configured in `quizRoutes.js`.
**Learning:** Uploading a very large file to an endpoint using `memoryStorage` causes the entire file to be buffered in RAM. Without size limits, this creates a critical Denial of Service (DoS) vulnerability, as an attacker can easily exhaust server memory and crash the Node.js process.
**Prevention:** Always configure explicit `limits: { fileSize: <bytes> }` when initializing `multer`, especially when using `memoryStorage()`.
## 2024-03-04 - [Path Traversal & Incomplete Regex Validation in File Uploads]
**Vulnerability:** The `uploadRoutes.js` deletion endpoint had weak path traversal validation that missed Windows `\` backslashes and potentially other edge cases. Additionally, the Multer `fileFilter` used unanchored regexes (like `/jpeg|jpg|png/`), allowing attackers to bypass validation with filenames like `malicious.png.exe`. Finally, the same unanchored regex was used for `extname`, leading to an accidental logic bug where legitimate `.svg` files were rejected.
**Learning:** Basic `includes('..')` checks are insufficient for robust directory traversal prevention across different platforms. Regexes for file extensions and mimetypes MUST be anchored to prevent partial matches.
**Prevention:** Always use `filename !== path.basename(filename)` for robust cross-platform path traversal prevention. Always anchor file validation regexes with `^` and `$` and split extension/mimetype validation checks to avoid overlapping matching errors.
## 2024-03-05 - Socket.io WebSocket CORS Misconfiguration
**Vulnerability:** The Socket.io WebSocket server in `socketService.js` was configured with an overly permissive CORS setup (`origin: '*'`), leaving it vulnerable to Cross-Origin WebSocket Hijacking (CSWSH) in production, bypassing the strict CORS rules implemented in the main Express app.
**Learning:** WebSocket connections often require separate CORS configuration from the main HTTP framework. If the Express app has strict CORS, the WebSocket server attached to it might still be completely open if not explicitly secured.
**Prevention:** Always mirror the main API's CORS policies when initializing WebSocket/Socket.io servers, specifically using `ALLOWED_ORIGINS` and verifying `NODE_ENV`. Calculate allowed origins once at startup for performance.

## 2024-03-08 - [Batch Upload Authorization Bypass]
**Vulnerability:** IDOR / Privilege Escalation in `adminBatchUpload` endpoint.
**Learning:** The endpoint parsed and processed Excel files for bulk inserts/updates but failed to verify if the requesting user (a subject admin) was authorized to add or modify questions for the specified `topic_id`.
**Prevention:** Always re-verify ownership or scope boundaries on bulk/batch endpoints, especially when parsing structured input where the target entity IDs (like `topic_id` or `question_id`) are provided by the user in the payload.

## 2025-05-22 - Insecure SSL Database Connection
**Vulnerability:** The database connection in `db.js` was configured to disable SSL certificate validation (`rejectUnauthorized: false`) when connecting to Supabase.
**Learning:** Disabling SSL certificate validation (`rejectUnauthorized: false`) makes the database connection vulnerable to Man-in-the-Middle (MITM) attacks. While often done to simplify setup with cloud providers that use self-signed or custom CAs, it bypasses the primary security guarantee of SSL.
**Prevention:** Always enforce `rejectUnauthorized: true` in production environments. Provide a mechanism (e.g., `DB_CA_CERT` environment variable) to supply the necessary CA certificates for the `pg` driver to verify the server's identity correctly.
