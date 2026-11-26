-- Queued wagers have no opponent. Their only terminal payout is a refund.
-- Preserve historical receipts while enforcing this invariant on new writes.
ALTER TABLE duel_wagers ADD CONSTRAINT duel_wagers_unmatched_refund
    CHECK (match_id IS NOT NULL OR payout IS NULL OR payout = amount) NOT VALID;
