# 🩺 ArborMed: Gamified Medical Education

![ArborMed Banner](https://via.placeholder.com/800x200?text=ArborMed+Gamified+Learning)

**ArborMed** is a cross-platform (Mobile + Web) application that transforms the rigorous, high-stress environment of medical education into a **cozy, gamified experience**. By combining advanced pedagogical algorithms with "cozy game" mechanics, we aim to improve long-term retention and motivation for medical students.

## 🎯 Vision & Goal

### The Problem
Medical students face an immense volume of raw information ("drinking from a firehose"), often leading to **burnout**, **anxiety**, and **inefficient rote memorization**. Traditional flashcard apps are effective but sterile and stressful.

### Our Solution
**"Cozy Competence"**: We believe that specific knowledge retention improves when anxiety is lowered. ArborMed bridges the gap between:
1.  **Rigorous Academic Standards**: Using Bloom's Taxonomy and Spaced Repetition (SM-2).
2.  **Low-Stress "Cozy" Gaming**: Using warm aesthetics, collecting mechanics, and ambient soundscapes to create a safe learning environment.

**Our Goal**: To help students achieve **clinical mastery** through consistent, low-stress daily practice, turning "studying" into a rewarding daily ritual.

---

## 🌟 Core Loop: "Learn to Earn, Build to Relax"

The application is built on a simple but powerful loop:
1.  **Study**: Complete adaptive quizzes to master medical topics (Haematology, Cardiology, Respiration, etc.).
2.  **Earn**: Correct answers reward you with **Stethoscopes (Coins)** and **XP**.
3.  **Build**: Spend coins in the **Medical Supply Shop** to buy meaningful equipment (e.g., ECG monitors, anatomical posters, cozy furniture).
4.  **Customize**: Decorate your personal virtual **Clinic/Study Room** with your unlocked items.

---

## 🧠 The Adaptive Engine: How It Works

ArborMed uses a sophisticated, multi-layered decision engine (`src/services/adaptiveEngine.js`) to determine the *exact* right question to show you next. It prioritizes **long-term retention** over short-term usage.

### 1. The Priority Queue 🚦
Every time you press "Start Quiz," the engine runs this check:
1.  **Predictive Override**: If a specific Bloom level is requested (e.g., for targeted practice), serve that immediately.
2.  **SRS (Leitner/SM-2) Due**: Are there questions you are about to forget? (Highest Priority). Checks for questions where `next_review_at <= NOW()`.
3.  **New Content (Bloom Climber)**: If no reviews are due, introduce new questions at your current cognitive level.

### 2. Spaced Repetition System (SRS) & SM-2 📅
We implement a dynamic **SM-2 Algorithm** (`src/services/analyticsEngine.js`) to combat the Forgetting Curve. Unlike simple Leitner boxes, this calculates precise intervals based on your performance quality (0-5 scale).

*   **Correct Answer (Quality >= 3)**:
    *   **Interval Growth**: The interval increases (1 day -> 6 days -> Previous Interval * Easiness Factor).
    *   **Easiness Factor (EF)**: Increases slightly, making future intervals grow faster for easy questions.
    *   **Mastery**: A question is considered "Mastered" after 3 consecutive correct repetitions.
*   **Incorrect Answer (Quality < 3)**:
    *   **Reset**: The interval resets to **1 day**.
    *   **Streak Reset**: Your consecutive correct streak for that question drops to 0.
    *   **Re-Learning**: The question effectively re-enters the learning phase.

### 3. Bloom's Taxonomy "Climber" 🧗
The app adapts not just to *what* you know, but *how deeply* you understand it. It uses 4 Bloom Levels:
*   **Level 1 (Remember)**: Basic recall facts.
*   **Level 2 (Understand)**: Explaining concepts.
*   **Level 3 (Apply)**: Clinical scenarios and diagnosis.
*   **Level 4 (Analyze)**: Complex multi-step case reasoning.

**Progression Logic**:
*   **Start**: Everyone starts at Level 1 for a new topic.
*   **Promotion**: You advance to the next level when you achieve a **20 Question Streak** (20 correct answers in a row at the current level) AND are currently below Level 4.
*   **Maintenance**: If you answer incorrectly, your streak resets to 0, requiring you to rebuild consistency before advancing.

### 4. True Mastery Score 📊
We calculate a weighted mastery score to reflect depth of understanding:
*   **Level 1-2 Questions**: 1.0x Weight
*   **Level 3-4 Questions**: 2.0x Weight
*   **Formula**:
    ```
    (Count(L1-2 Mastered) * 1 + Count(L3-4 Mastered) * 2)
    -------------------------------------------------------
    (Count(L1-2 Total) * 1 + Count(L3-4 Total) * 2)
    ```
*   *Result*: A percentage (0-100%) that rewards higher-order thinking more than basic recall.

---

## ⚔️ Duel Mode: Real-Time PvP

Challenge other students in real-time knowledge battles!

*   **Wager System**: Players bet **Stethoscopes (Coins)** to enter a duel.
*   **Matchmaking**: Powered by **Socket.IO**, the server pairs players with similar wagers.
*   **Gameplay**: Both players answer the same set of 3 questions.
*   **Winning**:
    *   The player with the higher score wins the pot (2x the wager).
    *   **Draw**: If scores are tied, both players get their wager back.
    *   **Disconnect**: If an opponent disconnects, you win by default.

---

## 🏥 The Ecosystem

### The Shop & Economy
The **Medical Supply Shop** is where your hard work pays off visually.
*   **Currency**: Stethoscopes (🩺). Scarcity is tuned to make high-tier items feel like genuine achievements.
*   **Inventory**: Medical equipment, cozy decor, and upgrades.
*   **The Room**: Your personal space that evolves with your knowledge.

### Localization & Inclusivity 🌍
*   **Bilingual Core**: Fully localized for **Hungarian (Magyar)** and **English**. Toggle instantly in settings.
*   **Accessibility**: High-contrast text options and screen-reader friendly structure.

---

## 🏗️ Technical Architecture

ArborMed uses a modern **Local-First Architecture** to ensure zero-latency learning and offline capability.

### **Frontend (Mobile & Web)**
*   **Framework**: [Flutter](https://flutter.dev/) (3.x).
*   **Local Database**: [Drift](https://drift.simonbinder.eu/) (SQLite) for robust offline storage.
*   **State Management**: `Provider` architecture.
*   **Sync**: Background synchronization engine to keep local progress in sync with the server.

### **Backend API**
*   **Runtime**: Node.js + Express.
*   **Real-time**: [Socket.IO](https://socket.io/) for Duel Mode.
*   **Database**: PostgreSQL (Hosted on Supabase).
*   **Services**:
    *   `adaptiveEngine.js`: The brain of the quiz logic.
    *   `analyticsEngine.js`: SM-2 algorithm and math.
    *   `socketService.js`: Manages real-time duel lobbies and game state.

---


## 📖 Codebase Documentation

The ArborMed codebase is heavily documented to aid in onboarding and maintainability.

*   **Backend (Node.js)**: Core services (like `adaptiveEngine.js` and `analyticsEngine.js`) and utility functions use **JSDoc** comments. This provides strict parameter definitions and return type hints for complex algorithms.
*   **Frontend (Flutter)**: The Dart codebase utilizes standard **Dartdoc** (`///`) comments. Key architecture components such as `ApiService`, state providers (`AuthProvider`), and routing endpoints are fully documented to explain their lifecycle and integration points.

## 🛠️ Developer Tools

The repository includes a suite of Python-based CLI tools to streamline content creation (`/tools`):

*   **`python tools/generate_voxel_hitboxes.py`**: Analyzes transparency to create interactive surface areas for the isometric room.
*   **`tools/hard_alpha_clip.py`**: Specialized image processor for medical assets.
*   **`tools/analyze_hitboxes.py`**: Debugging tool for room interactivity.

---

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (3.x+)
*   Node.js (18+)
*   PostgreSQL

### Installation
1.  **Clone the Repo**:
    ```bash
    git clone https://github.com/shubailo/arbor-med.git
    ```
2.  **Backend Setup**:
    ```bash
    cd services/backend
    npm install
    # Create .env file with DATABASE_URL, JWT_SECRET, etc.
    npm run dev
    ```
3.  **Mobile Setup**:
    ```bash
    cd apps/student_app
    flutter pub get
    # Run on Mobile
    flutter run

    # Run on Web
    flutter run -d chrome
    ```

---

*Built with ❤️ for Medical Students.*
