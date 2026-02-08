# Plan: Cleanup TK2 Generation Artifacts & Legacy Files

## 1. Goal
Remove all temporary files, scripts, and intermediate data generated during the TK2 question generation, translation, and upload process, AND organize the codebase by removing legacy artifacts.

## 2. Context & Risks
- **Context**: TK2 workflow is complete. TK7 and TK8 workflows appear to be complete (based on script names).
- **Status**: **Phase 1 (TK2) Cleanup executed.**

## 3. Scope of Cleanup

### Phase 1: TK2 Cleanup [COMPLETED]
- [x] Scripts: `combine_tk2.js`, `upload_tk2.js`, etc.
- [x] Intermediate Data: `tk2_combined_*.json`, `temp_chunk_*.txt`.
- [x] Source Buckets: `questions/pending/tk2_batch_*.json`.
- [x] Source Text: `TK2-text-2019.txt`.

### Phase 2: Legacy Organization (TK7, TK8, TKA6)
To neatly organize the codebase, we should remove artifacts from previous completed batches.

#### A. Legacy Source Files
- `TK7-text-2019.txt`
- `TK8-text-2019.txt`
- `temp_chunk.txt` (Root)

#### B. Legacy Scripts
**Action**: Delete these one-off scripts to declutter `scripts/` and `backend/scripts/`.
- `scripts/combine_and_validate_tk8.js`
- `scripts/normalize_tk8_batches.js`
- `scripts/translate_questions_tk8.js`
- `backend/scripts/list_topics_tk8.js`
- `backend/scripts/upload_tk8.js`
- `backend/scripts/upload_tk7.js`
- `backend/scripts/merge_tka6_questions.js`
- `backend/scripts/list_topics_temp.js`

## 4. Execution Plan (Phase 2)
1.  **Verification**: Confirm with user before deleting source texts (TK7, TK8).
2.  **Deletion**: Execute delete commands for the listed files.

## 5. Decision Points
> [!IMPORTANT]
> **User, please confirm Phase 2:**
> 1. Should I delete **TK7** and **TK8** source text files and scripts?
> 2. Should I delete `temp_chunk.txt`?
