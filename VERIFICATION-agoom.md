# AGOOM - Manual Verification Guide
> Verify the "Unified Backbone" implementation (Flutter + Node.js)

## 1. Start the Backend
1. Open a new terminal.
2. Navigate to `backend/`.
3. Run `npm run dev`.
4. Ensure you see: `Server running on port 3000` and `Database connection established`.

## 2. Start the Mobile App
1. **Recommended**: Double-click `run_mobile.bat` on your desktop. 
   - This prevents path issues and launches the app in **Chrome**.
2. **Alternative (Terminal)**:
   - `cd mobile`
   - `flutter run -d chrome`

## 3. Verify Registration Flow
- [ ] Tap **"Create Account"** on the Login screen.
- [ ] Enter `test@agoom.com` and password `password123`.
- [ ] Tap **Register**.
- [ ] verify you are navigated back (or to Dashboard).

## 4. Verify Login & Dashboard
- [ ] Enter the credentials above.
- [ ] Tap **Login**.
- [ ] **Verify**: You see "Welcome" with 0 Coins, 0 XP, Level 1.
- [ ] **Verify**: You see the list of Topic Cards (Cardiovascular, etc.).

## 5. Verify Adaptive Quiz
- [ ] Tap **"Cardiovascular System"**.
- [ ] **Verify**: A question loads with "Bloom: 1" and "Difficulty: 1".
- [ ] Select the **Correct Answer** (e.g., "Chest Pain" or "93.3" depending on question).
- [ ] **Verify**: Green checkmark appears + "Correct!".
- [ ] Tap **Next Question**.
- [ ] Answer correctly 3 times in a row.
- [ ] **Verify**: Difficulty or Bloom Level increases for the 4th question.

## 6. Verify Gamification (Backend Persistence)
- [ ] Close the app/browser and restart it.
- [ ] Login again.
- [ ] **Verify**: Your Coins and XP have increased based on your previous answers.

## Troubleshooting
- **Network Error**: The app automatically detects your environment:
  - **Web/iOS**: Uses `localhost:3000`.
  - **Android Emulator**: Uses `10.0.2.2:3000`.
- **Database Error**: Ensure Docker container `agoom_db` is running (`docker ps`).
