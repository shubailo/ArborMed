# PLAN: Systematic Medical Generation Workflow Update

Update the medical question generation workflow to produce continuous relational analysis statements and improve chunking logic to avoid cutting sentences.

## 🎯 Goal
- Improve data quality for medical question generation.
- Ensure context preservation in text chunks.
- Align relational analysis format with modern medical exam standards.

## 🛠️ Proposed Changes

### 1. Script Update: `read_file_chunk.js`
- **Location**: `content-engine/src/generation/read_file_chunk.js`
- **Logic**: 
    - Initial `end = start + length`.
    - If `end` is within text, search forward for the first occurrence of:
        - `". "` (Period + space)
        - `"! "`
        - `"? "`
        - `"\n"`
    - Apply a 500-character safety limit to the forward search.
    - Export the expanded chunk.

### 2. Workflow Update: `systematic-medical-generation.md`
- **Location**: `.agent/workflows/systematic-medical-generation.md`
- **Format**:
    - Relational Analysis: "[Effect], mert [Cause]."
    - Example: "Obstukciós ileusban a széklet színe világos, mert ilyenkor az epefestékek nem jutnak a bélbe."
- **Rules**:
    - Explicitly forbid "Statement I / Statement II" format.
    - Mandate continuous logical flow.

## ✅ Verification Plan
- [ ] Run `node content-engine/src/generation/read_file_chunk.js "SOURCE.txt" 0 5000 "test.txt"` and verify it ends at a sentence boundary.
- [ ] Verify the workflow file correctly renders the new rules.
