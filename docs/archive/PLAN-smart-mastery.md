# Plan: Smart Mastery & Agile Bloom System

The user requires a sophisticated learning engine that combines **Spaced Repetition (SRS)**, **Bloom's Taxonomy**, and a rigorous **Mastery Definition**.

## Core Philosophy
1.  **True Knowledge**: Correct answer != Mastery. Correctness over time (Retention) = Mastery.
2.  **Level Gating**: You cannot master the subject until you master the basics (Bloom 1).
3.  **Spaced Repetition**: Wrong answers reviewed immediately; Right answers spaced out.

## Phase 1: Database Schema Expansion
Enhance `user_topic_progress` and `user_question_progress` to track these advanced metrics.

-   **`user_question_progress`**:
    -   `consecutive_correct` (INT): Tracks streaks for specific items.
    -   `mastered` (BOOLEAN): True if `consecutive_correct >= 3`.
    -   `last_answered_at` (TIMESTAMP).

-   **`user_topic_progress`**:
    -   `unlocked_bloom_level` (INT): Max level available to user (1-4).
    -   `questions_mastered` (INT): Count of distinct questions with `mastered=true`.
    -   `total_questions_in_level` (INT): Denominator for percentage.

## Phase 2: The Adaptive Logic (Engine Upgrade)
Update `AdaptiveEngine.js` to implement the new "Agile Bloom" flowchart.

### A. Question Selection (`getNextQuestion`)
1.  **Priority 1 (The Review Queue)**: Fetch questions where `next_review_at <= NOW()`.
2.  **Priority 2 (The Frontier)**: Fetch NEW questions from `current_bloom_level`.
3.  **Priority 3 (The Reach)**: If unlocked, occasional Level+1 question.

### B. Result Processing (`processAnswerResult`)
1.  **SRS Logic**:
    -   **Correct**: `consecutive_correct++`, Box increases (1->3->7 days), `mastered` set to true if `>=3`.
    -   **Wrong**: `consecutive_correct = 0`, Box reset to 1 (Review Tomorrow/Next Session).
2.  **Bloom Promotion**:
    -   Check **Coverage**: If `(questions_mastered / total_questions_in_level) > 0.8`, increment `current_bloom_level`.
    -   Check **Streak**: If 5 correct **of current level** in a row, unlock next level questions temporarily.
3.  **Mastery Calculation**:
    -   `Mastery % = (Questions Mastered / Total Active Questions) * 100`.
    -   *Crucial*: This formula means score GROWS slowly as you convert "Seen" to "Mastered".

## Phase 3: Analytics & Frontend
-   **Dashboard**: Display "Bloom Level 1" badge next to the progress bar.
-   **Feedback**: "Question Mastered!" toast when a question hits 3 consecutive correct stats.

## Phase 4: Verification
-   Simulate 3 days of learning (using mocked timestamps).
-   Verify Mastery % stays 0% on Day 1 even with 100% accuracy.
-   Verify Mastery % jumps on Day 3 when items cross the threshold.
