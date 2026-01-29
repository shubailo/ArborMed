AGOOM – Complete Project Specification
Version: 1.0 Final
Platform: Flutter (iOS, Android, Web)
Target Users: Medical students (pathophysiology focus)

1. Project Vision & Goals
1.1 What is AGOOM?
AGOOM (Adaptive Gamified Oriented Medical-learning) is a mobile-first medical education platform that makes learning pathophysiology engaging, personalized, and effective through:

Adaptive quizzing that adjusts difficulty and cognitive level (Bloom's taxonomy) in real-time based on student performance.

Gamification with emotional accountability via a virtual "Clinical Companion" (Med Bean) that students help build a medical clinic for by answering questions correctly.

Subject mastery tracking with visual progress indicators (hexagonal radar charts, topic-level mastery bars).

Teacher/admin analytics to identify difficult questions, track student progress, and improve content quality.

1.2 Core Educational Philosophy
Bloom's Taxonomy progression: Questions span Remember (1) → Understand (2) → Apply (3) levels, with adaptive difficulty scaling.

Immediate feedback: Every answer gets instant correctness validation + explanation to reinforce learning.

Spaced practice: Encourage daily engagement through streaks and gentle reminders (not punitive).

Intrinsic motivation over extrinsic pressure: No lives/hearts system; unlimited attempts; focus on personal growth and helping the Bean.

1.3 Why Flutter?
Cross-platform: Single codebase for iOS, Android, and Web (admin dashboard can be web-based).

Native performance: Smooth animations for gamification elements (Bean reactions, coin animations).

Rich UI: Material/Cupertino widgets + custom illustrations for clinical theme.

Scalability: Easier to add future features (offline mode, notifications, AR medical models).

2. User Roles & Permissions
2.1 Student
Can:

Register/login (email/password or SSO).

Take adaptive quizzes (unlimited attempts).

View personal dashboard (mastery charts, XP, streak, coins).

Interact with Clinical Companion (Bean).

Shop for clinic items with earned coins.

Customize clinic layout.

View own performance history.

Cannot:

Access teacher/admin areas.

See other students' data (privacy-first).

Edit questions or analytics.

2.2 Teacher/Admin
Can:

Login to admin dashboard (web or mobile).

Create, edit, deactivate questions (CRUD operations).

Set question metadata: topic, Bloom level, difficulty, type, correct answers, explanations.

View aggregated analytics:

Question difficulty metrics (error rates, average response time).

Topic-level class performance.

Student engagement stats (anonymized or by cohort).

Export data (CSV/JSON) for research.

Manage student accounts (optional: assign to cohorts).

Cannot:

Take quizzes as a student (separate role).

Edit student progress data directly (read-only analytics).

2.3 Super Admin (Optional, post-MVP)
Can:

Manage teacher accounts.

Access global analytics (across multiple institutions).

Moderate content (approve/reject teacher-submitted questions).

3. Core Features & Modules
3.1 Authentication & Onboarding
Student Registration:

Email/password or university SSO (future: Google/Apple Sign-In).

Profile setup: Name, year of study, university (optional).

Choose starting Bean character (3–4 skins: Coffee Bean, Kidney Bean, Brain Bean, Heart Bean).

Teacher/Admin Login:

Separate login portal (web-preferred for admin dashboard).

Role-based access control (Firebase Auth or custom JWT).

3.2 Adaptive Quiz System
3.2.1 Question Bank Structure
Supported Question Types:

Single choice (MCQ with 1 correct answer)

Multiple choice (MCQ with 2+ correct answers)

True/False

Short text (exact match or keyword-based)

Matching pairs (e.g., match disease to symptom)

Ordering/Sequencing (e.g., order diagnostic steps)

Fill-in-the-blank

Hotspot (image-based, tap correct region – optional MVP+)

Question Metadata:

dart
class Question {
  String id;
  String subject; // 'pathophysiology'
  String topic; // 'cardiovascular', 'respiratory', etc.
  QuestionType type; // enum
  String text;
  List<String>? options; // for MCQ
  dynamic correctAnswer; // String, List<String>, or Map
  String explanation;
  int bloomLevel; // 1-3
  int difficulty; // 1-5
  bool active;
  String createdBy; // teacher ID
  DateTime createdAt;
}
3.2.2 Adaptive Engine Logic
Algorithm (Rule-based v1):

Starting point:

Bloom level: 1 (Remember)

Difficulty: 2–3 (medium)

Progression rules:

3 consecutive correct answers:

If Bloom < 3 → Bloom + 1

Else → Difficulty + 1 (max 5)

2–3 consecutive incorrect answers:

If Difficulty > 1 → Difficulty - 1

If Bloom > 1 → Bloom - 1

Question selection:

Pool: Questions matching current Bloom ± 1, Difficulty ± 1, active = true.

Exclude: Last 5 questions asked (avoid immediate repetition).

Random pick from pool.

Future enhancement (post-MVP):

Time decay: If >3 days since last quiz on a topic, reduce starting difficulty slightly.

Spaced repetition: Re-quiz previously incorrect questions after intervals (1d, 3d, 7d).

3.2.3 Quiz Flow (Student Experience)
Quiz Start Screen:

"Start Practice" button.

Option to filter by topic (e.g., "Cardiovascular only") – optional MVP.

Question Screen:

Progress indicator: "Question 5 of 15" + progress bar.

Question text (with image support if needed).

Answer options (rendered based on question type).

"Submit Answer" button.

Feedback Screen:

Immediate: Green checkmark (correct) or red X (incorrect).

Explanation text displayed.

Coin reward animation (+2 coins for correct).

Bean reaction animation (happy/sad).

"Next Question" button.

Quiz Summary Screen:

Total score: "12/15 correct (80%)".

Coins earned: "+28 coins 🪙".

XP earned: "+45 XP".

Breakdown by topic: "Cardiovascular 4/5, Respiratory 3/5...".

"Back to Dashboard" button.

3.3 Student Dashboard
Layout (scrollable sections):

Header:
Profile photo/avatar + student name.

Coin balance: "🪙 325 coins".

XP & Level: "Level 4 – 380/500 XP" (progress bar).

Streak: "🔥 7 day streak".

Section 1: Subject Mastery (Hexagonal Radar Chart)
6 axes: Cardiovascular, Respiratory, Gastrointestinal, Renal, Endocrine, Neurology.

Data: Each axis shows mastery % (0–100%, calculated from correct answer rate in that topic).

Visual: Teal/cyan filled polygon on dark navy background, glowing edges.

Title: "Subject Mastery" with target icon 🎯.

Section 2: Bloom-Level Progress
3 horizontal bars:

Remember (Bloom 1): 92% mastery (green).

Understand (Bloom 2): 78% mastery (yellow).

Apply (Bloom 3): 64% mastery (orange).

Each bar shows question count: "Remember: 45/50 correct".

Section 3: Quick Stats Cards
Card 1: Total Quizzes (e.g., "18 quizzes completed").

Card 2: Average Score (e.g., "82% correct").

Card 3: Total Study Time (optional: tracked in background).

Section 4: Recent Activity
List of last 5 quiz sessions: date, score, coins earned.

Bottom Nav:
Dashboard | Quiz | Clinic | Profile.

3.4 Clinical Companion (Gamification Core)
3.4.1 Meet the Bean
Character:

Small, round, cute medical-themed bean character.

Skins (choose at signup):

Coffee Bean (brown, energetic vibe).

Kidney Bean (red-brown, academic vibe).

Brain Bean (pink-grey, nerdy vibe).

Heart Bean (red, caring vibe).

Animations:

Idle: Bean sits/stands, occasionally blinks or looks around.

Happy: Jumps, claps, sparkles.

Sad: Droopy, small tear, looks down.

Studying: Holds tiny book, turns pages.

Celebrating: Confetti, throws hat (on level-up or streak milestone).

Emotion States (reactive to student actions):

Correct answer → Happy animation.

Incorrect answer → Sad (but encouraging message: "Let's try again!").

Quiz completed → Celebrating.

Long inactivity (3+ days) → Bean sits idle, waiting (no punishment, just visual cue).

3.4.2 Coin Economy
Earning Coins:

Per correct answer: +1 to +5 coins (scaled by Bloom level × difficulty).

Formula: coins = bloomLevel × difficulty.

Example: Bloom 2, Difficulty 3 → 6 coins.

Quiz completion bonus: +10 coins (regardless of score).

Streak bonus: +5 coins daily if quiz completed.

Perfect quiz (100% correct): +20 bonus coins.

Spending Coins (Clinic Shop):

Buy medical equipment and furniture to decorate Bean's clinic.

3.4.3 Clinic Shop & Customization
Shop UI:

Grid or list of items with:

Icon/image.

Name (e.g., "Stethoscope").

Price (e.g., 30 coins).

Category tag (e.g., "Cardiovascular").

"Buy" button (disabled if insufficient coins).

Item Categories (15–20 items MVP):

Cardiovascular Corner:

EKG Monitor (50 coins)

Stethoscope (30 coins)

Defibrillator (100 coins)

Heart Model (80 coins)

Respiratory Setup:

Spirometer (60 coins)

Oxygen Tank (70 coins)

Lung Anatomy Poster (40 coins)

Neurology Nook:

Reflex Hammer (25 coins)

Brain CT Scan Poster (90 coins)

Microscope (120 coins)

Gastrointestinal Gear:

Endoscope (110 coins)

Stomach Model (65 coins)

Renal & Endocrine:

Kidney Model (75 coins)

Hormone Chart (50 coins)

General Furniture:

Desk (20 coins)

Bookshelf (35 coins)

Exam Table (60 coins)

Waiting Room Chair (15 coins)

Plants, Lamps, Rugs (5–20 coins)

Clinic View:

Layout: 2D isometric or top-down view (like Animal Crossing / Habbo Hotel style).

Interaction: Tap-to-place items (optional: drag-and-drop for repositioning).

Bean placement: Bean "lives" in the clinic, reacts to new items (e.g., happy animation when new equipment placed).

Backgrounds: Start with empty clinic, gradually fills as items purchased.

Future (post-MVP):

Multiple rooms (Cardio Lab, Neuro Office, Surgery Room).

Rare/legendary items (Golden Stethoscope, MRI Machine).

Bean upgrades (Student Bean → Resident Bean → Attending Bean with visual costume changes).

3.5 Student Profile Page
Sections:

Avatar & Name: Editable.

Level & XP: Visual badge (e.g., "Level 5 Resident").

Streak Info: Current streak + longest streak ever.

Total Stats:

Quizzes completed.

Total questions answered.

Overall accuracy %.

Total study time.

Badges/Achievements (simple MVP):

Grid of unlocked/locked badges:

"First Quiz" (complete 1 quiz).

"Perfect Score" (100% on any quiz).

"10 Quizzes" (complete 10 quizzes).

"5-Day Streak" (maintain 5-day streak).

"Cardiovascular Master" (100% accuracy in 10 Cardio questions).

"100 Coins Earned" (earn 100 total coins).

Settings:

Change password.

Notification preferences (daily reminder toggle).

Dark/Light theme (optional).

Logout.

4. Teacher/Admin Dashboard (Web-first, Flutter Web or separate React)
4.1 Dashboard Home
Overview Cards:

Total Questions (e.g., "245 active questions").

Total Students (e.g., "82 students").

Average Class Score (e.g., "76%").

Most Active Topic (e.g., "Cardiovascular – 320 attempts this week").

Quick Actions:

"Add New Question" button.

"View Analytics" button.

"Export Data" button.

4.2 Question Management
Question List Page:

Table columns:

Question Text (truncated, clickable).

Type (icon: MCQ, T/F, etc.).

Topic (tag: Cardiovascular, etc.).

Bloom Level (1/2/3).

Difficulty (1–5 stars).

Error Rate (% incorrect, color-coded: green <30%, yellow 30–50%, red >50%).

Active Status (toggle switch).

Actions (Edit | Duplicate | Delete).

Filters (top bar):

Topic dropdown.

Bloom level multi-select.

Difficulty range slider.

"Problematic Questions Only" checkbox (error rate >40%).

Search: Full-text search in question text.

Question Editor (Modal or New Page):

Fields:

Question Text (rich text editor with image upload support).

Question Type (dropdown).

Options (dynamic list, add/remove options).

Correct Answer(s) (checkboxes or input).

Explanation (text area).

Topic (dropdown: 6 topics).

Bloom Level (1–3 radio buttons).

Difficulty (1–5 slider).

Active (toggle).

Actions:

Save | Cancel | Preview (shows how it looks in student quiz view).

Bulk Operations (future):

Import questions from CSV/JSON.

Export selected questions.

4.3 Analytics Dashboard
Section 1: Question Analytics

Table:

Question ID | Text (truncated) | Attempts | Error Rate % | Avg Response Time (sec).

Sortable by error rate (identify hardest questions).

Click question → drill-down:

Distribution of chosen answers (if MCQ).

Comments from students (future: flag confusing questions).

Chart:

Bar chart: Top 10 hardest questions (by error rate).

Section 2: Topic Performance

Table:

Topic | Total Attempts | Avg Score % | Mastery Level (color-coded).

Hexagonal Radar Chart (class-level):

Same 6-axis chart as student dashboard, but showing class average mastery per topic.

Section 3: Bloom-Level Analysis

Chart:

Horizontal bar chart:

Bloom 1 (Remember): 88% class avg.

Bloom 2 (Understand): 74% class avg.

Bloom 3 (Apply): 62% class avg.

Insight: "Students struggle most with Application-level questions. Consider adding more practice cases."

Section 4: Student Engagement

Metrics:

Active students this week.

Average quizzes per student.

Average streak length.

Dropout rate (students inactive >14 days).

Chart:

Line graph: Weekly active users over past 3 months.

Individual Student View (optional):

Search student by name/email.

View:

Personal mastery chart.

Quiz history.

Time spent per topic.

Weak areas (topics/Bloom levels <60% accuracy).

4.4 Export Functionality
Button: "Export Analytics"

Options:

Questions (all or filtered): CSV with columns: id, text, topic, bloom, difficulty, attempts, error_rate.

Student Performance: CSV with: student_id, name, quizzes_completed, avg_score, strong_topic, weak_topic.

Responses (raw data): CSV with: student_id, question_id, answer, correct, response_time, answered_at.

Use case: Teachers analyze in Excel/SPSS for research or course improvement.

5. Technical Architecture
5.1 Tech Stack
Frontend (Flutter):

Framework: Flutter 3.x (Dart).

State Management: Provider or Riverpod (for reactive state).

Routing: GoRouter (declarative routing).

UI Libraries:

Material 3 widgets.

Custom illustrations (Bean character, clinic items).

Charts: fl_chart package (radar, bar, line charts).

Animations: Lottie or Rive for Bean animations.

Backend:

Option A (Recommended): Firebase (Firestore for DB, Firebase Auth, Cloud Functions for adaptive logic).

Option B: Node.js/Express + PostgreSQL (REST API) + JWT auth (if prefer self-hosted).

Database Schema (Firestore structure):

text
users/
  {userId}/
    - email, name, role, year
    - xp, level, coins, streak, lastActiveDate
    - purchasedItems: [itemId1, itemId2...]
    
questions/
  {questionId}/
    - subject, topic, type, text, options, correctAnswer, explanation
    - bloomLevel, difficulty, active, createdBy, createdAt
    
quizSessions/
  {sessionId}/
    - userId, startedAt, completedAt
    - totalQuestions, correctCount, totalScore, avgDifficulty, coinsEarned, xpEarned
    
responses/
  {responseId}/
    - sessionId, questionId, userAnswer, correct, responseTimeMs, answeredAt
    
items/
  {itemId}/
    - name, category, price, imageUrl
    
userItems/
  {userItemId}/
    - userId, itemId, purchasedAt, positionX, positionY (for clinic layout)
APIs/Cloud Functions:

startQuiz(userId) → creates new QuizSession.

getNextQuestion(sessionId) → adaptive engine logic, returns next Question.

submitAnswer(sessionId, questionId, answer) → records Response, calculates correctness, awards coins/XP.

finishQuiz(sessionId) → finalizes session, updates user stats.

getDashboardData(userId) → aggregates mastery, Bloom stats, recent activity.

buyItem(userId, itemId) → deducts coins, adds to userItems.

Teacher APIs: CRUD for questions, analytics aggregations.

Third-party Services:

Auth: Firebase Auth or Auth0.

Storage: Firebase Storage (for question images, Bean sprites).

Analytics (optional): Firebase Analytics or Mixpanel (track user engagement).

Notifications: Firebase Cloud Messaging (daily reminder: "Your Bean misses you!").

5.2 Deployment
Mobile: Flutter build → iOS App Store + Google Play Store.

Web (Admin Dashboard): Flutter build web → host on Firebase Hosting or Vercel.

Backend: Firebase (serverless) or Dockerized Node.js on Railway/Render.

6. UI/UX Design Principles
6.1 Visual Style
Inspiration: Duolingo (friendly, playful, clean) + Medical theme (professional but not sterile).

Color Palette:

Primary: Teal/Cyan (#14B8A6) – represents knowledge, growth.

Secondary: Navy blue (#1E293B) – professionalism, depth.

Accent: Warm orange (#FB923C) – energy, encouragement.

Backgrounds: Light mode: off-white (#F8FAFC), Dark mode: dark navy (#0F172A).

Success: Green (#10B981), Error: Red (#EF4444), Warning: Yellow (#FBBF24).

Typography:

Sans-serif (e.g., Inter, Poppins) – modern, readable.

Hierarchy: Bold titles, medium subtitles, regular body.

Iconography:

Rounded, friendly icons (Heroicons or custom medical icons).

Bean character: custom-designed, multiple expressions.

Spacing & Layout:

Generous padding, clear sections.

Cards with rounded corners, subtle shadows.

Consistent button sizes (large tappable areas for mobile).

6.2 Accessibility
WCAG AA compliance: Contrast ratios >4.5:1 for text.

Screen reader support: Semantic labels for all interactive elements.

Font scaling: Respect system font size settings.

Color-blind friendly: Don't rely solely on color (use icons + text for correctness feedback).

6.3 Animations
Smooth transitions: Page navigation, modal open/close (300ms easing).

Micro-interactions:

Coin pop-in animation (+2 coins).

Bean reactions (200ms).

Progress bar fills.

Button press feedback (scale down slightly on tap).

Performance: Keep animations at 60fps (use Flutter's animation controllers).

7. Future Enhancements (Post-MVP)
Phase 2 Features
Clinical Cases Module:

Multi-step case scenarios (read patient history → answer diagnostic questions → choose treatment).

Branching narratives (decisions affect patient outcome).

Case completion awards bonus coins + special badge.

AI-Powered Features:

Question generation: GPT-4 creates new questions from textbook content (teacher reviews before publishing).

Personalized hints: If student stuck, AI suggests relevant concepts to review.

Chatbot tutor: Ask Bean medical questions, get AI-generated explanations.

Social Features (opt-in):

Study groups: Small cohorts (5–10 students) can see each other's clinic progress (inspiration, not competition).

Leaderboards: Weekly XP leaderboard (anonymous or opt-in only).

Challenges: Teacher assigns group challenge (e.g., "Everyone master Cardiovascular this week").

Advanced Analytics:

Learning curves: Track individual student progress over time (ML-based predictions of mastery).

Item Response Theory (IRT): Calibrate question difficulty based on student performance data.

Heatmaps: Visual map of where class struggles most (topic × Bloom level matrix).

Offline Mode:

Download questions for offline quizzing (e.g., during flights, low connectivity areas).

Sync progress when back online.

Internationalization:

Multi-language support (English, Spanish, German for EU medical schools).

AR/VR Integration:

AR mode: Point phone at body part → see 3D organ model + quiz questions.

VR clinic: Walk through Bean's clinic in VR (fun engagement boost).

8. Success Metrics & KPIs
8.1 Student Engagement
Daily Active Users (DAU): Target >60% of registered students active weekly.

Streak retention: >40% of students maintain 5+ day streak.

Quiz completion rate: >80% of started quizzes finished.

Average session length: 10–15 minutes (sweet spot for mobile learning).

8.2 Learning Outcomes
Mastery improvement: Average mastery per topic increases >15% over 4 weeks.

Bloom progression: >50% of students reach Apply level (Bloom 3) within 2 months.

Error rate reduction: Questions initially at 60% error rate drop to <40% after adaptive practice.

8.3 Teacher Adoption
Content contribution: Teachers add >10 new questions/week.

Analytics usage: >70% of teachers check analytics dashboard weekly.

Question quality: <5% of questions flagged as confusing/incorrect by students.

8.4 Monetization (Future)
Freemium model: Free tier (limited clinic items), Premium ($5/mo) unlocks all items + exclusive Bean skins.

Institutional licenses: Universities pay per-student for white-label version.

In-app purchases: Optional cosmetic Bean skins, special clinic themes.

9. Development Roadmap
Phase 0: Foundation (Weeks 1–2)
 Flutter project setup (iOS, Android, Web targets).

 Firebase/backend integration (Auth, Firestore).

 Basic routing (login → dashboard → quiz → clinic).

 Design system implementation (colors, typography, base widgets).

Phase 1: Core Quiz Engine (Weeks 3–5)
 Question data model + CRUD (teacher side).

 Adaptive engine logic (Cloud Function or local Dart).

 Quiz flow UI (question screen, feedback, summary).

 Response tracking + correctness calculation.

Phase 2: Student Dashboard (Week 6)
 Dashboard layout with stat cards.

 Hexagonal radar chart (fl_chart package).

 Bloom-level progress bars.

 Recent activity list.

Phase 3: Gamification (Weeks 7–9)
 Bean character design + animations (Rive/Lottie).

 Coin economy (earn, display, persist).

 Clinic shop UI + item database.

 Clinic view (2D layout, tap-to-place items).

 XP/leveling system + streak tracking.

Phase 4: Teacher Dashboard (Weeks 10–11)
 Question management UI (list, editor, filters).

 Analytics pages (question stats, topic performance, Bloom analysis).

 Export functionality (CSV download).

Phase 5: Polish & Testing (Weeks 12–14)
 Onboarding flow (tutorial for students).

 Error handling + offline state management.

 Accessibility audit (screen reader testing).

 Performance optimization (image caching, query indexing).

 Beta testing with 20–30 students (collect feedback).

Phase 6: Launch (Week 15+)
 App Store submission (iOS + Android).

 Marketing website (landing page with demo video).

 Teacher onboarding (workshop + documentation).

 Pilot study with 100 students (data collection for research).

10. Appendix: Example User Flows
10.1 Student: First Quiz Experience
Open app → See onboarding: "Meet your Clinical Companion! Help them build their dream clinic by answering questions."

Choose Bean skin → Select "Brain Bean".

Dashboard loads → See empty radar chart, 0 coins, Level 1.

Tap "Start Practice Quiz" → Quiz begins.

Question 1: "Define hypertension." (Bloom 1, Difficulty 2) → Answer correctly.

Feedback: Green checkmark, "+2 coins 🪙", Bean jumps happily, explanation shown.

Next 9 questions → Mix of correct/incorrect, difficulty adjusts.

Quiz Summary: "8/10 correct, +20 coins, +30 XP". Bean celebrates.

Return to Dashboard → Radar chart shows 80% in Cardiovascular, XP bar fills.

Tap "Clinic" → See empty clinic, open shop, buy first item (Stethoscope, 30 coins).

Place item → Bean reacts happily, clinic looks less empty.

10.2 Teacher: Adding a Question
Login to admin dashboard (web).

Dashboard → Questions → Add New Question.

Fill form:

Text: "Which of the following is a risk factor for stroke?"

Type: Multiple Choice.

Options: A) Hypertension, B) Diabetes, C) Smoking, D) All of the above.

Correct: D.

Explanation: "All listed are major modifiable risk factors for stroke."

Topic: Cardiovascular.

Bloom: 2 (Understand).

Difficulty: 3.

Save → Question appears in list, immediately available to students.

Check analytics (next week) → See question has 65% error rate → Edit to make clearer.

11. Final Notes
This specification represents the complete vision for AGOOM v1.0 as a Flutter application. The focus is on creating a delightful, effective learning experience through adaptive quizzing, emotional gamification (Clinical Companion), and actionable teacher analytics. The modular architecture allows for future expansion (cases, AI, social features) without requiring a full rewrite.
