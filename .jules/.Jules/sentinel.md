## 2026-04-05 - Prevent Mass Assignment in Quest Claims
**Vulnerability:** The `claimQuest` endpoint blindly trusted the client-provided `rewardTokens` amount, allowing an attacker to pass an arbitrarily large number and exploit the economy system (Mass Assignment/IDOR).
**Learning:** Client-provided inputs for economy state changes or reward amounts must always be validated and capped on the backend to prevent trivial exploits, even if the feature relies on client-side state.
**Prevention:** Strictly parse, validate, and cap all numeric inputs that affect user balances or privileges. Ideally, authoritative values should be fetched from the backend database.
