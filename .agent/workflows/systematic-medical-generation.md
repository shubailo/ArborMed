---
description: Structured generation of high-complexity medical questions from text chunks using read_file_chunk.js
---

# /generate-systematic - Systematic Medical Question Generation

Use this workflow to generate rigorous, high-complexity medical question banks batch-by-batch from large text files.

## 🚀 Phase 1: Environment Setup

1.  **Source Text**: Ensure your source file (e.g., `TK8-text-2019.txt`) is in the root directory.
2.  **Tracking**: Open/create `task.md` in your brain directory and list chunks (e.g., 5k, 10k, etc.).
3.  **Reading Tool**: Use the backend script to extract precise chunks:
    ```powershell
    node backend/scripts/read_file_chunk.js "SOURCE_FILE.txt" START_POS 5000 "temp_chunk.txt"
    ```

## 🧠 Phase 2: Generation Strategy (Aggressive Complexity)

When processing a chunk, adhere to the following strict distribution to maximize cognitive depth:

### Target Ratio (per 30-question batch)
| Question Type | Target Count | Bloom Level Focus |
| :--- | :--- | :--- |
| **Relational Analysis** | 5 - 6 | Level 3-4 (Analyze causal chains) |
| **Multiple Choice (Select all)** | 5 - 7 | Level 3-4 (Synthesis of findings) |
| **Single Choice** | 8 - 12 | Level 2-3 (Application of concepts) |
| **Matching / True-False** | Max 2-6 total | Level 1-2 (Critical definitions only) |

### ID Format
`tk[BATCH_ID]_[SEQ]` (e.g., `tk8_1`, `tk8_2`)

## ✍️ Item-Writing Rules (Systematic)

1.  **Relational Analysis**: 
    - *Format*: "Statement I: [X]. Statement II: [Y]."
    - *Options*: (I and II true + explanation), (I and II true + no explanation), (I true, II false), (I false).
2.  **Multiple Choice**: Use "Select all that apply". Provide 4-6 options.
3.  **Consistency**: Keep options concise. Avoid "all/none of the above".
4.  **Edge Cases**: If a 5,000-character chunk lacks enough unique concepts for 30 high-quality questions, merge it with the adjacent block and generate 60 questions from 10,000 characters.

## 📝 JSON Schema
Ensure the output matches the bilingual mapping requirements:
```json
[
  {
    "id": "tkX_Y",
    "type": "single_choice | multiple_choice | relational_analysis | matching | true_false",
    "bloom_level": 1-4,
    "question_text": "text (EN)",
    "options": ["Op1", "Op2", "Op3", "Op4"],
    "correct_answer": "exact string match",
    "explanation": "Rationale for correctness"
  }
]
```

## 🔄 Phase 3: Post-Processing
Once batches are generated:
1.  Run `/translate-and-sync` to localize into Hungarian.
2.  Upload via `node backend/scripts/upload_questions.js`.