# PLAN-high-density-qgen - Automated Question Generation

```markdown
> **Detailed plan to implement high-density question generation (30 questions per 5000 characters) from source text.**

---

## 🎯 Question Diversity & Depth

### Supported Question Types
The generation logic must ensure a diverse set of question formats:
- **SCQ**: Single Choice Questions.
- **MCQ**: Multiple Choice Questions.
- **T/F**: True/False statements.
- **Pair Together**: Matching items from two columns.
- **Relation Analysis**: Assertion-Reasoning style questions.

### Bloom's Taxonomy Integration
Questions must be distributed across all cognitive levels (1-6):
- **Levels 1-2 (Remember/Understand)**: Primarily SCQ, T/F, and Matching.
- **Levels 3-4 (Apply/Analyze)**: Focus on **Relation Analysis** and complex MCQs.
- **Levels 5-6 (Evaluate/Create)**: Scenario-based MCQs and complex synthesis questions.

*Note: Relation Analysis questions are specifically targeted at Bloom levels 3 and 4 to evaluate the understanding of causality and logical links.*
```

## 🏗️ Overview

### Goal
Automate the generation of high-quality medical questions from PDF/Text sources at a very high density (approx. 1 question per 166 characters).

### Context
-   **Current State**: Manual or chunk-based generation via CLI wizard.
-   **Desired State**: Fully automated script that ingests a file, splits it into 5000-character chunks, and generates 30 questions for *each* chunk, aggregating the results.

### Success Criteria
-   [ ] Script `backend/scripts/dense_generate.js` created.
-   [ ] Input: Accepts PDF or Text file path.
-   [ ] Processing: Splits text into ~5000 char chunks (respecting sentence boundaries).
-   [ ] Generation: Calls Gemini API for each chunk -> 30 questions.
-   [ ] Output: Saves aggregated JSON to `backend/src/data/questions/generated_[filename].json`.
-   [ ] Rate Limiting: Handles API limits gracefully.

---

## 🛠️ Tech Stack

| Component | Technology | Rationale |
|-----------|------------|-----------|
| **Runtime** | Node.js | Existing backend environment. |
| **AI Model** | Gemini Pro 1.5 | Large context window, JSON mode. |
| **PDF Parsing** | `pdf-parse` | Existing dependency. |
| **Validation** | Zod / Manual JSON check | Ensure schema compliance. |

---

## 📂 File Structure

```text
backend/
├── scripts/
│   ├── dense_generate.js      # [NEW] Main script
│   └── utils/
│       ├── chunker.js         # [NEW] Text splitting logic
│       └── gemini_client.js   # [REF] AI interaction
└── src/
    └── data/
        └── questions/         # Output directory
```

---

## 📋 Task Breakdown

### Phase 1: Core Logic (Scripting)

- [ ] **Task 1.1: Implement Text Chunker** <!-- id: 5 -->
    -   **Input**: Raw text string.
    -   **Logic**: Split into 5000-char blocks, but snap to nearest period (.) or newline to avoid cutting sentences.
    -   **Verify**: Unit test with sample text.

- [ ] **Task 1.2: Create Generation Script (`dense_generate.js`)** <!-- id: 6 -->
    -   **Input**: File path argument.
    -   **Logic**:
        1.  Read file (PDF/Text).
        2.  Clean text (remove headers/footers).
        3.  Loop through chunks.
        4.  Call AI (Prompt: "Generate 30 questions...").
        5.  Sleep 2-5s between calls (Rate limit).
        6.  Push to `allQuestions` array.
    -   **Verify**: Run on small sample (10k chars).

- [ ] **Task 1.3: Prompt Engineering** <!-- id: 7 -->
    -   **Goal**: Ensure LLM actually produces *30* questions (often they stop at 10).
    -   **Strategy**: "You MUST generate exactly 30 questions. Number them 1-30."
    -   **Verify**: check output count.

### Phase 2: Refinement & Safety

- [ ] **Task 2.1: JSON Validation & deduplication** <!-- id: 8 -->
    -   **Logic**: Parse AI response, ensure `id`, `type`, `bloom_level` exist.
    -   **Verify**: Script does not crash on malformed JSON.

---

## ✅ Phase X: Verification Checklist

- [ ] Script runs without error on `TK4-text-2019.txt` (sample).
- [ ] Output JSON contains correct Question count (e.g., 50k chars -> ~300 questions).
- [ ] Questions are valid JSON.
- [ ] No duplicate IDs.
