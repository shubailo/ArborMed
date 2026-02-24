## 2025-02-23 - Login Timing Attack
**Vulnerability:** The `login` function in `authController.js` had a timing side-channel. If a user was not found, it returned immediately without performing a password hash comparison, whereas valid users triggered a slow `bcrypt.compare`. This allowed enumeration of valid email addresses.
**Learning:** Even if `bcrypt` handles timing-safe comparisons internally, the application logic must ensure the comparison is actually invoked in all code paths to prevent timing differences based on user existence.
**Prevention:** Always perform a hash comparison, even if the user is not found. Use a dummy hash (valid format) for the comparison to ensure similar execution time.
