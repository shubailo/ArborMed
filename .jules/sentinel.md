## 2025-02-23 - Login Timing Attack
**Vulnerability:** The `login` function in `authController.js` had a timing side-channel. If a user was not found, it returned immediately without performing a password hash comparison, whereas valid users triggered a slow `bcrypt.compare`. This allowed enumeration of valid email addresses.
**Learning:** Even if `bcrypt` handles timing-safe comparisons internally, the application logic must ensure the comparison is actually invoked in all code paths to prevent timing differences based on user existence.
**Prevention:** Always perform a hash comparison, even if the user is not found. Use a dummy hash (valid format) for the comparison to ensure similar execution time.

## 2025-02-24 - Race Condition in Shop Purchase (Balance Check)
**Vulnerability:** The `buyItem` function in `shopController.js` used a "check-then-act" pattern where user balance was checked outside a locked context, and then deducted. This allowed concurrent requests to potentially spend the same coins multiple times, leading to negative balances or unauthorized item acquisition.
**Learning:** Checking a value and then acting on it in separate database operations is inherently unsafe in concurrent environments, even if wrapped in a naive transaction without row-level locking.
**Prevention:** Use atomic SQL updates with conditional `WHERE` clauses (e.g., `UPDATE ... WHERE coins >= price`) or row-level locking (`SELECT ... FOR UPDATE`) to ensure the condition remains true at the exact moment of the update.
