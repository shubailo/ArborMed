# PLAN: User Compensation for Inventory Loss

The goal is to compensate users who lost their inventory due to a technical glitch. We will provide them with a generous amount of in-game currency and a formal apology via the in-app notification system.

## Proposed Strategy

1. **Currency Grant**: Add **500 Coins** to every user account. This allows them to repurchase their favorite items and discover new ones.
2. **Global Apology**: Send a broadcast notification to all 5 users explaining the situation and the compensation.

## Task Breakdown

### Phase 1: Preparation
- [ ] Create a standalone Node.js script `tools/compensate_users.js` that:
    - [ ] Connects to the database.
    - [ ] Updates all users' coin balances.
    - [ ] Inserts a broadcast notification for every user.
- [ ] Verify the script logic against the existing `users` and `notifications` tables.

### Phase 2: Execution
- [ ] Run the `tools/compensate_users.js` script.
- [ ] Verify that coin balances are updated.
- [ ] Verify that notifications are delivered.

### Phase 3: Reporting
- [ ] Provide a summary of how many users were compensated and what they received.

## Verification Checklist
- [ ] SQL query for updating coins returns success for all rows.
- [ ] SQL query for notifications inserts new rows for all user IDs.
- [ ] User balance check (random sample) confirms +5,000 coins.
