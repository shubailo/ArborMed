# Plan: Review Cardiovascular Questions

## Goal
Review and refine `backend/src/data/questions/cardovascular_questions.json` to ensure every question is understandable without additional context (self-contained), answers/explanations are correct, and both English and Hungarian phrasing are professional and grammatically perfect. Relational analysis questions must follow a specific single-sentence structure.

## Context
The file contains ~29,000 lines of medical questions. Relational analysis questions currently use a "Statement I. XX. Statement II. YY." format which needs to be converted.

## Task Breakdown

### Phase 1: Context & Analysis
- [x] **Scan File:** Identify all "relational_analysis" items.
- [ ] **Identify Dependencies:** Check for "based on the text" references.

### Phase 2: Content Refinement (Iterative)
#### 2.1 Relational Analysis Formatting
- [ ] **Convert Structure:** Transform "Statement I: [X]. Statement II: [Y]." into "[X], because/but/and [Y]." (or similar connecting words).
- [ ] **Hungarian Translation:** Apply same logic to `question_text_hu`.
- [ ] **Ensure Connection:** The second part should connect to the first so the user can evaluate the relationship.

#### 2.2 Cleanup & Professionalism
- [ ] **Remove "Text" References:** Base explanations on general medical knowledge.
- [ ] **Professional Phrasing:** Remove "Probably", "Maybe", "Actually the text says" from explanations.
- [ ] **Language Polish:** Fix awkward translations (e.g., "leads in the periphery" -> "originates in the periphery").

#### 2.3 Fact Checking
- [ ] Verify answers (e.g., physiological values like "200 bpm" for athletes) against medical standards.

### Phase 3: Technical Validation
- [ ] **JSON Structure:** Ensure no syntax errors.
- [ ] **Consistency:** Match `correct_answer` strings with updated `options`.

## Verification Checklist
- [ ] Relational analysis questions are single-sentence with connectors.
- [ ] No "Statement I / II" labels remain.
- [ ] Explanations are self-contained (no "text" references).
- [ ] Explanations are definitive (no "Probably").
- [ ] Hungarian phrasing is natural, professional, and grammatically perfect.
- [ ] Medical facts are accurate.
- [ ] JSON is valid.
