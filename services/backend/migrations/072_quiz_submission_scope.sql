-- Historical receipts have an unknown offline scope. New receipts preserve it.
ALTER TABLE responses ADD COLUMN submission_scope TEXT;

ALTER TABLE responses
    ADD CONSTRAINT responses_submission_owner
        CHECK (submission_id IS NULL OR user_id IS NOT NULL) NOT VALID,
    ADD CONSTRAINT responses_submission_scope_shape
        CHECK (submission_scope IS NULL OR
            (submission_id IS NOT NULL AND session_id IS NULL AND
             char_length(submission_scope) <= 128)) NOT VALID;
