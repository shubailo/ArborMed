# PLAN: Medical Question Editors & Standardized Schema

## Context
The current question editing system is monolithic and "unusable" for specialized medical exam types like **Relation Analysis** and **1-to-1 Matching**. We need to transition to a typed JSONB structure in the `content` column and implement a "morphing" UI editor that adapts to the selected question type.

---

## Phase 1: Backend Foundation (API & Registry)
Standardize the JSON structure for each type to ensure validation and correct client-side rendering.

### 1.1 Standardize `content` Schema
- **Relation Analysis**:
  ```json
  {
    "statement1": {"en": "...", "hu": "..."},
    "statement2": {"en": "...", "hu": "..."},
    "link_word": {"en": "because", "hu": "mert"},
    "correct_option": "A" 
  }
  ```
- **Multiple Choice (Multi-select)**:
  ```json
  {
    "is_multi": true,
    "correct_indices": [0, 2]
  }
  ```
- **Matching (1-to-1)**:
  ```json
  {
    "pairs": [
      {"left": {"en": "A", "hu": "A"}, "right": {"en": "1", "hu": "1"}},
      {"left": {"en": "B", "hu": "B"}, "right": {"en": "2", "hu": "2"}}
    ]
  }
  ```

### 1.2 Update Registry & Logic
- Modify `backend/src/services/questionTypes/registry.js` to validate these structures.
- Ensure `adminCreateQuestion` and `adminUpdateQuestion` in `quizController.js` handle these payloads correctly.

---

## Phase 2: Mobile UI Refactor (Dynamic Editors)
Transition `QuestionEditorDialog` from a hardcoded layout to a dynamic polymorphic layout.

### 2.1 Refactor `QuestionEditorDialog`
- Replace static list logic with a `Switch` statement on `_questionType`.
- Implement "Instant Morphing": Fields reset/change immediately upon type selection.

### 2.2 Create Type-Specific Editor Widgets
- `RelationAnalysisEditor`: 4 text fields (S1-EN/HU, S2-EN/HU) + linking word fields + Radio (A-E).
- `MultipleChoiceEditor`: List of options with Checkboxes (instead of Radio) for multi-select.
- `MatchingEditor`: Dynamic list of pairing fields.
- `TrueFalseEditor`: Simplified single statement editor.

### 2.3 Localization Support
- The "Translate All" button must be updated to traverse the new nested `content` structures during the AI translation call.

---

## Phase 3: Renderer Synchronization
Ensure the student-facing UI matches the new schema.

- Update `relation_analysis_renderer.dart` to read `statement1`, `statement2`, and `link_word` from `content`.
- Update `matching_renderer.dart` to render the pair list correctly.

---

## Verification Plan

### Automated
- **Migration Test**: Run seeding script `backend/src/scripts/seedBloomQuestions.js` with new structures.
- **API Unit Test**: Validate that saving a Matching question stores the expected JSON in the DB.

### Manual (UX Audit)
- Verify `Relation Analysis` options A-E match standard medical examination logic.
- Verify "Translate All" accurately populates Hungarian fields for Matching pairs.
- Confirm "Instant Morphing" doesn't crash the dialog state in Flutter.

---

## Agent Assignments
- **Backend Specialist**: Logic/Registry/Migration.
- **Frontend Specialist**: Flutter Dynamic UI/Editors.
- **Orchestrator**: Final verification and E2E testing.
