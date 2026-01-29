---
name: question-factory
description: Generates high-quality, curriculum-aligned multiple choice questions from source texts using AI.
---

# Question Factory Skill

This skill defines the methodology for generating educational content from raw text.

## 🧠 Pedagogical Principles

### Bloom's Taxonomy Levels
1.  **Recall (Level 1)**: Basic facts, definitions, recall.
    *   *Keywords*: What, Who, Define, List.
2.  **Comprehension (Level 2)**: Understanding concepts, explaining ideas.
    *   *Keywords*: Explain, Summarize, Interpret.
3.  **Application (Level 3)**: Using knowledge in new situations (Clinical Cases).
    *   *Keywords*: Apply, Solve, Demonstrate, Use.
4.  **Analysis (Level 4)**: Drawing connections, diagnosing.
    *   *Keywords*: Analyze, Differentiate, Compare.
5.  **Evaluation (Level 5)**: Justifying a stand or decision (Treatment plans).
    *   *Keywords*: Evaluate, Argue, Select/Justify.
6.  **Creation (Level 6)**: Producing new or original work. (Less applicable to MCQ).

### Question Quality Standards
-   **Distractors**: Wrong answers must be plausible. No "Mickey Mouse" answers.
-   **Clarity**: Stems should be clear and concise.
-   **Explanation**: Every question must have an explanation that clarifies the correct answer AND addresses why distractors might be chosen.

## 🛠️ Operational Workflow
1.  **Ingest**: Read text from PDF/Chapter.
2.  **Chunk**: Split text into semantic sections (approx 1000-2000 tokens).
3.  **Prompt**: Send chunk + Level Constraint + "Act as Medical Examiner" prompt to LLM.
4.  **Validate**: Ensure JSON structure matches the app's schema.
5.  **Insert**: Append to the correct topic file.
