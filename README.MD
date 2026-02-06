# 🩺 ArborMed: Gamified Medical Education

![ArborMed Banner](https://via.placeholder.com/800x200?text=ArborMed+Gamified+Learning)

**ArborMed** is a cross-platform (Mobile + Desktop) application that transforms the rigorous, high-stress environment of medical education into a **cozy, gamified experience**. By combining advanced pedagogical algorithms with "cozy game" mechanics, we aim to improve long-term retention and motivation for medical students.

## 🎯 Vision & Goal

### The Problem
Medical students face an immense volume of raw information ("drinking from a firehose"), often leading to **burnout**, **anxiety**, and **inefficient rote memorization**. Traditional flashcard apps are effective but sterile and stressful.

### Our Solution
**"Cozy Competence"**: We believe that specific knowledge retention improves when anxiety is lowered. ArborMed bridges the gap between:
1.  **Rigorous Academic Standards**: Using Bloom's Taxonomy and Spaced Repetition.
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
1.  **SRS (Leitner) Due**: Are there questions you are about to forget? (Highest Priority)
2.  **New Content (Bloom)**: If no reviews are due, introduce new questions at your current cognitive level.
3.  **Buffer/Practice**: If you are caught up, serve random reinforcement questions.

### 2. Spaced Repetition System (SRS) 📅
We implementation a modified **Leitner Box System** to combat the Forgetting Curve:
*   **Box 0**: New / Wrong Answer (Review in 5 minutes)
*   **Box 1**: 1 Day interval
*   **Box 2**: 3 Days interval
*   **Box 3**: 7 Days interval
*   **Box 4**: 14 Days interval
*   **Box 5**: 30 Days interval (Mastered)

*Logic*: Getting a question wrong **immediately** drops it back to Box 1, ensuring you re-learn gaps before moving on.

### 3. Bloom's Taxonomy "Climber" 🧗
The app adapts not just to *what* you know, but *how deeply* you understand it.
*   **Level 1 (Remember)**: Basic recall facts (e.g., "What is the normal range of...").
*   **Level 2 (Understand)**: Explaining concepts (e.g., "Why does anemia cause...").
*   **Level 3 (Apply)**: Clinical scenarios and diagnosis.
*   **Level 4 (Analyze)**: Complex multi-step case reasoning.

**Promotion Logic**:
*   You advance to the next level when you achieve **>80% Coverage** of the current level OR hit a **20 Question Streak**.
*   **Demotion**: 3 consecutive wrong answers will lower the difficulty to reinforce fundamentals.

### 4. True Mastery Score 📊
We don't just count "correct answers." Your mastery score is weighted:
*   **Mastered (Box 3+)**: 1.0 Points
*   **Learning (Box 0-2)**: 0.5 Points
*   **Unseen**: 0.0 Points
*   *Result*: You cannot achieve 100% mastery by cramming. You must prove retention over time.

---

## 🏥 The Ecosystem

### The Shop & Economy
The **Medical Supply Shop** is where your hard work pays off visually.
*   **Currency**: Stethoscopes (🩺). Scarcity is tuned to make high-tier items feel like genuine achievements.
*   **Inventory**:
    *   **Medical Equipment**: Gurneys, microscopes, skeletons.
    *   **Decor**: Rugs, plants, coffee machines.
    *   **Upgrades**: Better lighting, wallpapers.
*   **The Room**: Your personal space that evolves with your knowledge. A fully decked-out clinic is a badge of honor showing you have mastered many topics.

### Localization & Inclusivity 🌍
*   **Bilingual Core**: Fully localized for **Hungarian (Magyar)** and **English**. Toggle instantly in settings.
*   **Accessibility**: High-contrast text options and screen-reader friendly structure (Semantics).

---

## 🛠️ The Professor's Toolkit (Admin Dashboard)

A comprehensive management suite for educators to track progress and manage curriculum.

*   **Real-time Analytics**: Segmented data across Summary, Topics, and ECG performance.
*   **Question Management**:
    *   **Batch Upload**: Easily import hundreds of questions via Excel/CSV.
    *   **Live Preview**: Test how questions look on mobile before publishing.
    *   **Granular Statistics**: See which questions students find hardest.
*   **Smart Analytics**:
    *   **Weakness Heatmap**: Visual radar charts showing proficiency gaps.
    *   **Readiness Score**: A predictive score (0-100%) indicating probability of passing exams based on retention stability.

---

## 🏗️ Technical Architecture

ArborMed shifted to a **Local-First Architecture** in 2025 to ensure zero-latency learning and offline capability.

### **Mobile App (Frontend)**
*   **Framework**: [Flutter](https://flutter.dev/) (3.x).
*   **State Management**: `Provider` architecture with reactive streams.
*   **Local Database**: [Drift](https://drift.simonbinder.eu/) (SQLite) for cross-platform persistence.
*   **Sync Engine**: Intelligent background synchronization with Supabase/PostgreSQL.
*   **Design System**: Custom "Cozy" Design System featuring:
    *   **Z-Layered Rendering**: Pixel-perfect isometric room rendering.
    *   **Haptic Feedback**: Heartbeat haptics for correct answers.
    *   **Dynamic Audio**: Adaptive background lo-fi tracks that evolve with usage.

### **Backend API**
*   **Runtime**: Node.js + Express.
*   **Security**: Helmet, CORS, and Bcrypt hashing.
*   **Database**: PostgreSQL (Hosted on Supabase) utilizing optimized relational queries and JSONB for complex medical metadata.
*   **Services**:
    *   `adaptiveEngine.js`: The brain of the quiz logic.
    *   `analyticsEngine.js`: Time-decay retention modelling.

---

## 🛠️ Developer Tools

The repository includes a suite of Python-based CLI tools to streamline content creation (`/tools`):

*   **`python tools/add_furniture.py`**: A 1-click command to add new furniture assets. Handles alpha-clipping, voxel hitbox generation, and SQL entry creation automatically.
*   **`tools/hard_alpha_clip.py`**: Specialized image processor for medical assets.
*   **`tools/generate_voxel_hitboxes.py`**: Analyzes transparency to create interactive surface areas for the isometric room.

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
    cd backend
    npm install
    # Create .env file with DATABASE_URL, JWT_SECRET, etc.
    npm run dev
    ```
3.  **Mobile Setup**:
    ```bash
    cd mobile
    flutter pub get
    flutter run
    ```

---

*Built with ❤️ for Medical Students.*
