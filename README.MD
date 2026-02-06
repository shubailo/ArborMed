# 🩺 MedBuddy: Gamified Medical Education

**MedBuddy** is a cross-platform mobile application that transforms rigorous medical study into a cozy, gamified experience. It combines advanced pedagogical algorithms with "cozy game" mechanics to improve retention and motivation for medical students.

![MedBuddy Banner](https://via.placeholder.com/800x200?text=MedBuddy+Gamified+Learning)

## 🌟 Core Loop: "Learn to Earn, Build to Relax"

The application is built on a simple but powerful loop:
1.  **Study**: Complete adaptive quizzes to master medical topics (Haematology, Cardiology, etc.).
2.  **Earn**: Correct answers reward you with **Stethoscopes (Coins)** and **XP**.
3.  **Build**: Spend coins in the **Medical Supply Shop** to buy meaningful equipment (e.g., ECG monitors, anatomical posters, cozy furniture).
4.  **Customize**: Decorate your personal virtual **Clinic/Study Room** with your unlocked items.

---

## 🧠 Advanced Learning System

MedBuddy uses a multi-layered approach to ensure you don't just memorize, but *understand* medicine.

### 1. Bloom's Taxonomy "Climber" 🧗
The app adapts to your proficiency level using **Bloom's Taxonomy**:
*   **Level 1 (Remember)**: Basic recall facts.
*   **Level 2 (Understand)**: Explaining concepts.
*   **Level 3 (Apply)**: Clinical scenarios and diagnosis.
*   **Level 4 (Analyze)**: Complex multi-step case reasoning.

*How it works*: As you answer correctly, you "Level Up" to harder cognitive tiers. If you struggle, the system gently lowers the tier to reinforce basics.

### 2. Spaced Repetition System (SRS) 📅
We use a **Leitner Box System** to ensure long-term retention. Mastered questions re-appear *just* as you are about to forget them, while failed questions are prioritized.

### 3. Localization & Multi-lingual Support 🌍
Fully localized for **Hungarian** (Magyar) and **English**. 
*   Toggle languages seamlessly in the settings.
*   All medical topics, questions, and explanations are available in both languages.

### 4. ECG Master Practice 🫀
A dedicated module for interpreting Electrocardiograms.
*   Interactive interpretation steps (Rate, Rhythm, Axis, P-wave, QRS, etc.).
*   **Gold Standard Feedback**: Compare your findings against expert analysis with detailed report cards.

---

## 🏥 The Shop & Economy

The **Medical Supply Shop** is where your hard work pays off visually.

*   **Currency**: Stethoscopes (🩺).
    *   **Earn**: You earn **1-4 coins** per correct answer (scaled by question difficulty).
    *   **Social**: Receive **5 coins** whenever a colleague likes your clinical study room.
*   **Inventory**:
    *   **Medical Equipment**: Gurneys, microscopes, skeletons.
    *   **Decor**: Rugs, plants, coffee machines.
    *   **Upgrades**: Better lighting, wallpapers.
*   **The Room**: Your personal space that evolves with your knowledge. A fully decked-out clinic is a badge of honor showing you have mastered many topics.

---

## 🛠️ The Professor's Toolkit (Admin Dashboard)

A comprehensive management suite for educators to track progress and manage curriculum.

*   **Real-time Analytics**: Segmented data across Summary, Topics, and ECG performance.
*   **Question Management**:
    *   **Batch Upload**: Easily import hundreds of questions via Excel/CSV.
    *   **Live Preview**: Test how questions look on mobile before publishing.
    *   **Granular Statistics**: See which questions students find hardest.
*   **User Management**: Monitor student registration, activity, and mastery scores.
*   **Predictive Study History**: Refined student logs with unified scrolling, "Needs Attention" insights, and readiness scores.
*   **Teacher Notifications**: Send broadcast messages to all students directly through the app.
*   **Mobile-Responsive Design**: Manage the entire classroom from any device.

---

## 🔒 Security & Authentication

*   **Secure Access**: JWT (JSON Web Token) with short-lived access and secure rotate-on-use refresh tokens.
*   **OAuth2 Integration**: One-tap login with **Google**.
*   **Robust Account Recovery**: OTP-based (One Time Password) password reset via email.
*   **Role-Based Access (RBAC)**: Strict separation between `student` and `teacher` capabilities.

---

## 🏗️ Technical Architecture

MedBuddy shifted to a **Local-First Architecture** in 2025 to ensure zero-latency learning and offline capability.

### **Mobile App (Frontend)**
*   **Framework**: [Flutter](https://flutter.dev/) (3.x).
*   **State Management**: `Provider` architecture with reactive streams.
*   **Local Database**: [Drift](https://drift.simonbinder.eu/) (SQLite) for cross-platform persistence (WASM on Web, native SQLite on Mobile).
*   **Sync Engine**: Intelligent background synchronization with the PostgreSQL cloud.
*   **Design**: Custom "Cozy" Design System featuring:
    *   **Progressive Analytics**: Segmented "Daily Prescription" goals with elastic pulse physics (optimized for daily focus).
    *   **Immersive Audio**: Heartbeat haptics and dynamic medical atmosphere (optimized for Darwin/Android audio mixing).
    *   **Crash-Resilient Charting**: Key-based state reset strategy and null-safe list access to prevent race conditions during rapid data transitions.
    *   **Z-Layered Rendering**: Pixel-perfect isometric room rendering with voxel-based hitboxes.

### **Backend API**
*   **Runtime**: Node.js + Express.
*   **Security**: Helmet, CORS, and Bcrypt hashing.
*   **Database**: PostgreSQL (Hosted on Supabase) utilizing optimized relational queries and JSONB for complex medical metadata.

---

## 🛠️ Developer Tools & Automation

The repository includes a suite of Python-based CLI tools to streamline content creation:

*   **`python tools/add_furniture.py`**: A 1-click command to add new furniture. Handles:
    *   Automatic ID assignment & Catalog registration.
    *   Alpha-clipping & downscaling for 2048px source images.
    *   Automatic generation of Voxel Hitboxes and Image Metadata.
    *   Generates the SQL needed for backend synchronization.
*   **`tools/hard_alpha_clip.py`**: Specialized image processor for medical assets.
*   **`tools/generate_voxel_hitboxes.py`**: Analyzes transparency to create interactive surface areas.

---

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (3.x+)
*   Node.js (18+)
*   PostgreSQL (Local or Cloud)

### Installation
1.  **Clone the Repo**:
    ```bash
    git clone https://github.com/shubailo/med-buddy.git
    ```
2.  **Backend Setup**:
    ```bash
    cd backend
    npm install
    # Create .env file with DATABASE_URL, JWT_SECRET, MAIL_USER, MAIL_PASS, etc.
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
