# Plan: Hungarian Medical Question Translation Pipeline

## Goal
Translate ~33 `high_density_batch_*.json` files containing medical questions into Hungarian. The process involves AI-based translation, an automated AI review step for quality assurance, and merging all questions into a single import-ready JSON file.

## User Review Required
> [!NOTE]
> **No API Key Strategy**: Since no API key is available, we will use the `deep-translator` library (Google Translate backend) for free automated translation.
> **Quality Note**: While good, this may not achieve "perfect" medical accuracy compared to human or high-end LLM translation. A manual review step is highly recommended.

## Proposed Changes

### Backend
#### [NEW] [translate_pipeline.py](file:///c:/Users/shuba/Desktop/Med_buddy/backend/scripts/translate_pipeline.py)
A Python script to orchestrate the pipeline:
1.  **Load**: Iterate through `backend/src/data/questions/high_density_batch_*.json`.
2.  **Translate**: Use `deep_translator` to batch translate text.
3.  **Process**: Translate fields: `question`, `options` (values), `explanation`. **Keep `topic`/`subtopic` in English** to maintain compatibility with system IDs (unless verified otherwise).
4.  **Save**: Write intermediate `translated_batch_*.json` files.
5.  **Merge**: Combine into `backend/src/data/questions/all_questions_hungarian.json`.

#### [NEW] [hungarian_merge.py](file:///c:/Users/shuba/Desktop/Med_buddy/backend/scripts/hungarian_merge.py)
(Optional separate script, likely integrated into `translate_pipeline.py`)

## Verification Plan

### Automated Verification
- **JSON Validation**: The script will validate that the output is valid JSON.
- **Structure Check**: Verify that all keys (`question`, `options`, `correctAnswer`, `explanation`, `topic`, `subtopic`) are preserved and translated (except keys themselves, if they map to DB fields). *Note: confirming if keys should be translated or kept English for the DB schema.* -> *Assumption: Keys stay English, values are translated.*

### Manual Verification
1.  **Spot Check**: Manually review a random sample of 5-10 questions from the final merged file.
2.  **Import Test**: Attempt to import the final JSON into the application (using the existing import logic, if available) or verify it loads in a simple test script.

## Pipeline Steps
1.  **Setup**: Create `backend/src/data/questions/hungarian/` directory.
2.  **Script Implementation**: Write `translate_pipeline.py`.
3.  **Execution**: Run the script. This may take some time.
4.  **Final Review**: User/Human checks the `all_questions_hungarian.json`.
