# PLAN-question-processing.md

## Goal
Process 23 batches of generated questions (TK7), translate them into Hungarian, combine them into a single dataset, and upload them to the ArborMed backend.

## User Review Required
> [!IMPORTANT]
> **Topic Assignment**: The current question batches (`tk7_batch_*.json`) do not have a `topic_id` assigned. We need to determine if these should be assigned to an existing topic (e.g., "Gastrointestinal System", "Oral Cavity") or if a new "TK7" topic should be created.
> **Proposal**: I will create a script that prompts for a `topic_id` or creates a new topic named "Oral Cavity & GI (TK7)" if it doesn't exist.

> [!WARNING]
> **Translation Quality**: I will use my internal translation capabilities. While high quality, they may need manual review by a medical professional for nuance.

## Proposed Changes

### 1. Data Processing & Translation
I will create a script `scripts/process_questions.js` that:
- **Quality Check**:
    - Validates presence of `question_text`, `options`, `correct_answer`.
    - Checks that `correct_answer` matches one of the `options`.
    - Flags questions with very short text (< 10 chars) or malformed data.
- **Topic Assignment**:
    - Automatically assigns `topic_id` corresponding to **Pathophysiology > Gastrointestinal System**.
    - I will fetch the correct ID dynamically during the script execution.
- **Translation**:
    - Iterates through `backend/src/data/questions/tk7_batch_*.json`.
    - Maps and translates content to Hungarian (`_hu` fields).
- **Output**: Saves `backend/src/data/questions/tk7_combined_bilingual.json`.

### 2. Database Upload
I will check/create a script `backend/scripts/upload_questions.js` that:
- Reads `backend/src/data/questions/tk7_combined_bilingual.json`.
- Connects to the database.
- Inserts questions with bilingual data.

### 3. Workflow Creation
I will create a reusable workflow `.agent/workflows/translate-and-sync.md` that documents:
- How to place new JSON files.
- How to run the translation/quality script.
- How to upload to the server.

## Verification Plan

### Automated Verification
- **Script Dry Run**: `node backend/scripts/upload_questions.js --dry-run`
- **Quality Report**: The processing script will generate `logs/quality_report.txt` listing any skipped/flagged questions.

### Manual Verification
1. Open Admin Panel.
2. Check **Pathophysiology > Gastrointestinal System**.
3. Verify bilingual toggle works.

## Task Breakdown
- [ ] Research Topic ID for "Gastrointestinal System"
- [ ] Create `scripts/process_questions.js` (Translation + Quality Check)
- [ ] Run processing script
- [ ] Create `backend/scripts/upload_tk7.js`
- [ ] Create workflow `.agent/workflows/translate-and-sync.md`
- [ ] Upload and Verify
