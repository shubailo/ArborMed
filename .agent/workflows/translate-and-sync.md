# /translate-and-sync - Question Translation & Sync Workflow

## Description
This workflow automates the process of validating, translating, and uploading new question batches to the ArborMed backend.

## Prerequisites
- Node.js environment
- Backend running (for database connection)

## Steps

### 1. Place Question Files
Put new question JSON files (e.g., `batch_X.json`) into:
`backend/src/data/questions/`

### 2. Combine and Validate
Run the validation script to check for errors and combine batches:
```bash
node scripts/combine_and_validate.js
```
*Output: `backend/src/data/questions/combined_en.json`*

### 3. Translate (Bilingual En/Hu)
Run the translation script (uses Google Translate API):
```bash
node scripts/translate_questions.js
```
*Output: `backend/src/data/questions/combined_bilingual.json`*

#### 3b. Fix Missing Translations (Optional)
If API rate limits caused some translations to fail, run the fix script:
```bash
node scripts/fix_missing_translations.js
```

### 4. Upload to Database
Run the upload script to insert questions into the **Pathophysiology > Gastrointestinal System** topic (or other configured topics):
```bash
node backend/scripts/upload_tk7.js
```

## Maintenance
- **Quality Check**: Review `scripts/combine_and_validate.js` to adjust validation rules.
- **Topic Config**: Edit `backend/scripts/upload_tk7.js` to change target topics.
