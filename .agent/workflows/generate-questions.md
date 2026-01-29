---
description: Generates quiz questions from PDF books using AI
---

# Generate Questions Workflow

This workflow guides you through generating high-quality questions from your PDF library.

## prerequisites
-   PDFs in `book/` folder
-   Google Gemini API Key (or configured environment variable `GEMINI_API_KEY`)

## 🚀 How to Run

1.  Open your terminal.
2.  Run the question generator wizard:
    ```bash
    node backend/scripts/generate_questions.js
    ```
3.  **Select Book**: Choose the PDF you want to process.
4.  **Select Level**: Choose the target Bloom's Taxonomy level (1-4).
    -   *Level 1*: Recall (Facts)
    -   *Level 2*: Application (Scenarios)
    -   *Level 3*: Analysis (Why?)
    -   *Level 4*: Evaluation (Decisions)
5.  **Target Topic**: Choose an existing topic file or create a new one.
6.  **Review & Save**: The script will show you a preview. Type 'y' to save them to the database.

## 🧠 Tips
-   The script currently samples a chunk from the middle of the book. For full processing, you can modify the script to iterate through all pages.
-   Ensure your API key has quota available.
