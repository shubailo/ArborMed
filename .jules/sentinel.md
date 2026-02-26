## 2025-02-23 - Login Timing Attack
**Vulnerability:** The `login` function in `authController.js` had a timing side-channel. If a user was not found, it returned immediately without performing a password hash comparison, whereas valid users triggered a slow `bcrypt.compare`. This allowed enumeration of valid email addresses.
**Learning:** Even if `bcrypt` handles timing-safe comparisons internally, the application logic must ensure the comparison is actually invoked in all code paths to prevent timing differences based on user existence.
**Prevention:** Always perform a hash comparison, even if the user is not found. Use a dummy hash (valid format) for the comparison to ensure similar execution time.

## 2025-02-23 - Shop Balance Race Condition
**Vulnerability:** A "Check-Then-Act" race condition in `shopController.js` allowed users to purchase items even with insufficient balance if concurrent requests were made, because the balance check (`SELECT`) was separate from the deduction (`UPDATE`).
**Learning:** In highly concurrent systems, separate read and write operations within a transaction do not guarantee consistency unless row locks (`FOR UPDATE`) are used. Without locks, another transaction can modify the value between the read and the write.
**Prevention:** Use atomic database updates with conditional `WHERE` clauses (e.g., `UPDATE ... SET balance = balance - cost WHERE balance >= cost`) to enforce constraints directly in the database operation. Check the `rowCount` to determine if the operation succeeded.
