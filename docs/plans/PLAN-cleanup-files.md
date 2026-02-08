# Plan: Cleanup TK2 Generation Artifacts & Legacy Files

## 1. Goal
Remove all temporary files, scripts, and intermediate data generated during the TK2 question generation, translation, and upload process, AND organize the codebase by removing legacy artifacts.

## 2. Context & Risks
- **Context**: TK2 workflow is complete. Legacy files (TK7, TK8, TKA6) removed.
- **Status**: **Cleanup executed.**

## 3. Scope of Cleanup

### Phase 1: TK2 Cleanup [COMPLETED]
- [x] Scripts: `combine_tk2.js`, `upload_tk2.js`, etc.
- [x] Intermediate Data: `tk2_combined_*.json`, `temp_chunk_*.txt`.
- [x] Source Buckets: `questions/pending/tk2_batch_*.json`.
- [x] Source Text: `TK2-text-2019.txt`.

### Phase 2: Legacy Organization [COMPLETED]
- [x] Source Files: `TK7-text-2019.txt`, `TK8-text-2019.txt`, `temp_chunk.txt`.
- [x] Legacy Scripts:
    - `scripts/combine_and_validate_tk8.js`
    - `scripts/normalize_tk8_batches.js`
    - `scripts/translate_questions_tk8.js`
    - `backend/scripts/list_topics_tk8.js`
    - `backend/scripts/upload_tk7.js`
    - `backend/scripts/upload_tk8.js`
    - `backend/scripts/merge_tka6_questions.js`
    - `backend/scripts/list_topics_temp.js`

## 4. Execution Plan (Completed)
1.  **Delete TK2 Artifacts**: Done.
2.  **Delete Legacy Files**: Done.

## 5. Result
The environment is now clean and organized. Only active scripts and project files remain.
