# Arbormed Coin (Stethoscope) Economy & Progression Design

## 1. Core Philosophy & Constraints
*   **Target Earning Rate:** ~150 Coins per day for an engaged player.
*   **Basic Items (e.g., Desk, Exam Table):** ~100-200 Coins (1-2 days of regular play).
*   **Fancy Items (e.g., Room Aesthetic):** ~400-500 Coins (3-4 days of regular play).
*   **Separation of Currencies:**
    *   **XP (Experience Points):** The "Social Flex". Scales infinitely, ranks players on Leaderboards, and satisfies the "Achiever" archetype.
    *   **Coins (Stethoscopes):** The "Self-Expression". Used exclusively for shop items and consumables. Earn rates are kept flat to prevent high-level hyper-inflation.

---

## 2. Earning Sources & The Soft Cap

### A. Core Gameplay: Quiz Sessions
*   **Questions 1–50 (Daily):** 1 Coin per correct answer.
*   **Questions 51+ (Daily):** 1 Coin per every 5 correct answers.
*   **UI/UX for the Soft Cap:** To prevent the "+1 Coin" from looking broken or a "+0.2" from looking messy, we introduce a **"Research Grant Progress Bar"** in the UI once the soft cap is hit.
    *   Instead of coins popping out immediately, correct answers fill a small circular progress bar next to the coin total.
    *   When the bar fills (after 5 correct answers), it "pops" and awards the 1 Coin. This clearly communicates diminishing returns while maintaining a satisfying, visual progression loop.
    *   **Resilience (Wrong Answers):** If a player is 4/5 of the way to a coin and gets a question wrong, the bar **does not reset**. The goal of the soft cap is to reward volume and persistence, not to punish mistakes. A reset would be demoralizing and discourage a struggling student from continuing their study session.

### B. Daily Quests (Capped at ~60 Coins/Day)
Current frontend quests reward 50-100 coins each. These should be nerfed to provide a steady, guaranteed daily income:
*   **Easy Quest:** 10 Coins
*   **Medium Quest:** 20 Coins
*   **Hard Quest:** 30 Coins

### C. The Progression Trap (Leveling Up Shouldn't Feel Punishing)
If a Level 10 player must answer 30 questions for a 20-coin quest, while a Level 1 player only answers 10, leveling up feels like a tax.
*   **The Solution:** Do not scale the *Coin* reward, but scale the *Status* reward.
    *   A Level 10 player's Hard Quest might be: "Diagnose 5 Rare Cases" (Level 3/4 Bloom questions).
    *   They still get 30 Coins, but completing it awards a massive multiplier to **XP**, and unlocks exclusive **"Titles"** (e.g., "Chief Resident", "Attending Physician") that are displayed publicly next to their name.
    *   This ensures high-level quests feel like prestigious challenges meant to flex expertise, rather than just more grind for the same pay.

### D. Social & Streaks (Capped at ~40 Coins/Day)
*   **Daily Login Streak:** Day 1 (5 coins), Day 2 (10 coins), Day 3+ (15 coins).
*   **Social (Room Likes):** Earn 5 Coins when a colleague likes your room (Capped at 25 Coins/Day to prevent alt-account farming).

---

## 3. Coin Sinks & Inflation Control (The Vibe)

To solve the "Veteran Player Problem," the economy relies on robust, continuous sinks that strictly adhere to a **Scholarly/Medical Excellence** theme.

### A. Consumable Sinks (Short-Term)
*   **The Heart System (Future):** The #1 most reliable sink. If a player runs out of "Hearts" (stamina) from answering incorrectly, they can spend Coins to refill a Heart immediately and continue studying.
    *   **Veteran Bypassing (Progressive Pricing):** To prevent a veteran with 5,000 coins from enjoying "Unlimited Study Mode" indefinitely, the cost of a Heart Refill increases if used multiple times in a single 24-hour window (e.g., 1st refill = 50 Coins, 2nd = 100 Coins, 3rd = 200 Coins). This forces even the richest players to eventually stop and wait for the daily reset.
*   **Streak Freeze:** Players can buy a "Freeze" for **200 Coins** to protect their daily login streak if they miss a day.

### B. "Clinical Supply Crates" (The Gacha Alternative)
We must avoid the "Casino Mystery Box" vibe. Instead, introduce **"Clinical Supply Crates"** or **"Research Grants"** for **150 Coins**.
*   **The Flavor:** You are funding hospital research. In return, the hospital grants you surplus or experimental equipment.
*   **The Drops:** Guaranteed random decor item. However, there is a 5% chance of a "Breakthrough" drop—state-of-the-art medical equipment (e.g., a glowing holographic anatomical heart, a high-end electron microscope, or an animated EKG monitor for the wall). This provides a massive, thematic sink for completionists.
*   **Duplicate Handling (Ethics):** If a crate drops a stackable item (e.g., a potted plant, a chair), the user keeps it (they can now place two in their room). If it drops a "Unique" item they already own (e.g., a specific "Winter Window"), they receive a **"Grant Rebate"** (a partial refund of 50 Coins). This feels fair and thematic without breaking the economy.

### C. Prestige & Expansion
*   **Specialty Wards:** Allow veterans to buy a "Second Clinic" or "Specialty Ward" (e.g., Pediatrics, Surgery) for **2,000 Coins**. This provides an entirely empty, new room to decorate from scratch, instantly draining massive coin reserves.
    *   **Furniture Logic:** Inventory is **not globally cloned**. If a veteran wants their "Mahogany Executive Desk" in the Pediatrics Ward, they must unassign it from the Main Clinic, or buy a *second* one. This is a crucial, massive coin sink for endgame collectors who want fully furnished, distinct rooms simultaneously.

### D. Seasonal Decors (Collection vs. Decay)
*   **The Mechanic:** Every 3 months, introduce limited-time items (e.g., "Winter Solstice Desk", "October Anatomy Skeletons"). These cost 3x normal items and disappear from the shop after the season.
*   **The Vibe (Permanent Collection):** Once bought, the player keeps the item permanently. Having a "Halloween Skeleton" next to an exam table in July isn't "out of place"—it becomes a **vintage flex**. It signals to other players: *"I was studying here last October and earned this rare item."* This permanent FOMO drives massive short-term coin spending without requiring frustrating "maintenance" mechanics.