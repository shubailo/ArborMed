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
