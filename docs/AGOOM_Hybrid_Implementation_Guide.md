This guide combines architectural patterns from:

Edutainment (Adaptive Quiz Engine)

Repository: https://github.com/lyes-mersel/edutainment

Key feature: Adaptive learning based on child performance
​

Tech: Flutter + Firebase (Auth + Firestore)
​

Flutter Quiz Firebase (Backend + Admin Panel)

Repository: https://github.com/devishree2305/Flutter_quiz_app

Key feature: Admin panel for quiz management, multi-subject structure

Traditional vs. AGOOM: Expected Learning Outcomes 
Tech: Flutter + Firebase Authentication + Cloud Firestore

FlexyCoin (Gamification UI)

Repository: https://github.com/AmirBayat0/FlexyCoin-CryptocurrencyApp

Key feature: Dashboard, coin balance, favorites, dark/light mode

Tech: Flutter + GetX

1. Project Structure (AGOOM-specific)
text
agoom/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── question.dart
│   │   ├── user.dart
│   │   ├── quiz_session.dart
│   │   ├── clinic_item.dart
│   ├── services/
│   │   ├── firebase_service.dart
│   │   ├── adaptive_engine.dart
│   │   ├── auth_service.dart
│   ├── screens/
│   │   ├── student/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── quiz_screen.dart
│   │   │   ├── clinic_screen.dart
│   │   │   ├── shop_screen.dart
│   │   │   ├── profile_screen.dart
│   │   ├── admin/
│   │   │   ├── question_list_screen.dart
│   │   │   ├── question_editor_screen.dart
│   │   │   ├── analytics_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   ├── widgets/
│   │   ├── coin_balance_widget.dart
│   │   ├── radar_chart_widget.dart
│   │   ├── shop_item_card.dart
│   │   ├── bean_character_widget.dart
│   ├── utils/
│   │   ├── constants.dart
│   │   ├── theme.dart
├── assets/
│   ├── images/
│   ├── animations/
├── pubspec.yaml
2. Adaptive Quiz Engine
Inspired by Edutainment's Performance-Based Question Selection

Concept
​
Track user correctness rate per topic

Adjust Bloom level (Remember → Understand → Apply) based on performance

Adjust difficulty (1-5 scale) dynamically

Algorithm (Simplified)
dart
// lib/services/adaptive_engine.dart

class AdaptiveEngine {
  // Track recent performance (last 5 answers)
  List<bool> recentAnswers = [];
  
  Question getNextQuestion({
    required String userId,
    required String topic,
    required int currentBloomLevel,
    required int currentDifficulty,
    required List<String> excludeQuestionIds, // Last 5 questions
  }) {
    // Calculate adaptation
    int correctCount = recentAnswers.where((a) => a == true).length;
    int incorrectCount = recentAnswers.where((a) => a == false).length;
    
    int targetBloom = currentBloomLevel;
    int targetDifficulty = currentDifficulty;
    
    // Progression rules (from AGOOM spec)
    if (correctCount >= 3) {
      // 3 consecutive correct → increase challenge
      if (targetBloom < 3) {
        targetBloom += 1; // Bloom 1 → 2 → 3
      } else {
        targetDifficulty = (targetDifficulty + 1).clamp(1, 5); // Max difficulty 5
      }
      recentAnswers.clear();
    } else if (incorrectCount >= 2) {
      // 2-3 incorrect → decrease challenge
      if (targetDifficulty > 1) {
        targetDifficulty -= 1;
      } else if (targetBloom > 1) {
        targetBloom -= 1;
      }
      recentAnswers.clear();
    }
    
    // Query Firestore for matching question
    return FirebaseService().getRandomQuestion(
      topic: topic,
      bloomLevel: targetBloom,
      difficulty: targetDifficulty,
      excludeIds: excludeQuestionIds,
    );
  }
  
  void recordAnswer(bool isCorrect) {
    recentAnswers.add(isCorrect);
    if (recentAnswers.length > 5) {
      recentAnswers.removeAt(0); // Keep last 5 only
    }
  }
}
Key Takeaway: This mirrors Edutainment's "Tailored questions based on child's performance", adapted for medical education with Bloom taxonomy.
​

3. Firebase Backend Setup
Inspired by Flutter Quiz Firebase's Firestore Structure

Firestore Collections
text
users/
  {userId}/
    - name: "John Doe"
    - email: "john@example.com"
    - role: "student" | "admin"
    - coins: 125
    - xp: 380
    - level: 4
    - streak: 7
    - lastActiveDate: Timestamp
    - topicMastery: {
        cardiovascular: 0.82,
        respiratory: 0.67,
        gastrointestinal: 0.74,
        renal: 0.58,
        endocrine: 0.63,
        neurology: 0.71
      }

questions/
  {questionId}/
    - text: "Which of the following is a symptom of hypertension?"
    - type: "single_choice" | "multiple_choice" | "true_false"
    - options: ["Headache", "Dizziness", "Chest pain", "All of the above"]
    - correctAnswer: "All of the above"
    - explanation: "Hypertension commonly presents with..."
    - subject: "pathophysiology"
    - topic: "cardiovascular"
    - bloomLevel: 2  // 1=Remember, 2=Understand, 3=Apply
    - difficulty: 3  // 1-5 scale
    - active: true
    - createdBy: {adminUserId}
    - createdAt: Timestamp

quizSessions/
  {sessionId}/
    - userId: {userId}
    - startedAt: Timestamp
    - completedAt: Timestamp
    - totalQuestions: 15
    - correctCount: 12
    - totalScore: 80
    - coinsEarned: 28
    - xpEarned: 45

responses/
  {responseId}/
    - sessionId: {sessionId}
    - questionId: {questionId}
    - userAnswer: "All of the above"
    - isCorrect: true
    - responseTimeMs: 8500
    - answeredAt: Timestamp

clinicItems/
  {itemId}/
    - name: "Stethoscope"
    - category: "cardiovascular"
    - price: 30
    - imageUrl: "gs://bucket/stethoscope.png"

userItems/
  {userItemId}/
    - userId: {userId}
    - itemId: {itemId}
    - purchasedAt: Timestamp
    - positionX: 50  // For clinic layout (optional MVP+)
    - positionY: 120
Firebase Service Implementation
dart
// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // --- QUESTIONS CRUD (Admin) ---
  
  Future<void> addQuestion(Question question) async {
    await _firestore.collection('questions').add(question.toMap());
  }
  
  Future<void> updateQuestion(String questionId, Question question) async {
    await _firestore
        .collection('questions')
        .doc(questionId)
        .update(question.toMap());
  }
  
  Future<void> deleteQuestion(String questionId) async {
    await _firestore
        .collection('questions')
        .doc(questionId)
        .update({'active': false}); // Soft delete
  }
  
  // --- QUIZ FLOW (Student) ---
  
  Future<Question> getRandomQuestion({
    required String topic,
    required int bloomLevel,
    required int difficulty,
    required List<String> excludeIds,
  }) async {
    QuerySnapshot snapshot = await _firestore
        .collection('questions')
        .where('topic', isEqualTo: topic)
        .where('bloomLevel', isEqualTo: bloomLevel)
        .where('difficulty', isGreaterThanOrEqualTo: difficulty - 1)
        .where('difficulty', isLessThanOrEqualTo: difficulty + 1)
        .where('active', isEqualTo: true)
        .limit(10)
        .get();
    
    // Filter out recently asked questions
    List<Question> questions = snapshot.docs
        .map((doc) => Question.fromFirestore(doc))
        .where((q) => !excludeIds.contains(q.id))
        .toList();
    
    questions.shuffle();
    return questions.first;
  }
  
  Future<void> submitAnswer({
    required String sessionId,
    required String questionId,
    required String userAnswer,
    required bool isCorrect,
    required int responseTimeMs,
  }) async {
    await _firestore.collection('responses').add({
      'sessionId': sessionId,
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'responseTimeMs': responseTimeMs,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }
  
  // --- GAMIFICATION ---
  
  Future<void> awardCoins(String userId, int coins) async {
    await _firestore.collection('users').doc(userId).update({
      'coins': FieldValue.increment(coins),
    });
  }
  
  Future<void> purchaseItem(String userId, String itemId, int price) async {
    // Transaction to ensure atomic operation
    await _firestore.runTransaction((transaction) async {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      DocumentSnapshot userSnapshot = await transaction.get(userRef);
      
      int currentCoins = userSnapshot.get('coins');
      if (currentCoins < price) {
        throw Exception('Insufficient coins');
      }
      
      // Deduct coins
      transaction.update(userRef, {'coins': currentCoins - price});
      
      // Add item to user's collection
      transaction.set(_firestore.collection('userItems').doc(), {
        'userId': userId,
        'itemId': itemId,
        'purchasedAt': FieldValue.serverTimestamp(),
      });
    });
  }
  
  // --- ANALYTICS (Admin) ---
  
  Future<Map<String, double>> getQuestionErrorRates() async {
    QuerySnapshot responsesSnapshot = await _firestore
        .collection('responses')
        .get();
    
    Map<String, int> questionAttempts = {};
    Map<String, int> questionErrors = {};
    
    for (var doc in responsesSnapshot.docs) {
      String qId = doc.get('questionId');
      bool correct = doc.get('isCorrect');
      
      questionAttempts[qId] = (questionAttempts[qId] ?? 0) + 1;
      if (!correct) {
        questionErrors[qId] = (questionErrors[qId] ?? 0) + 1;
      }
    }
    
    Map<String, double> errorRates = {};
    questionAttempts.forEach((qId, attempts) {
      int errors = questionErrors[qId] ?? 0;
      errorRates[qId] = (errors / attempts) * 100;
    });
    
    return errorRates;
  }
}
Key Takeaway: This structure mirrors Flutter Quiz Firebase's "4 subjects (NLP, ML, BDA, Blockchain)", adapted for AGOOM's 6 medical topics + admin CRUD.

4. Gamification UI Components
Inspired by FlexyCoin's Dashboard & Shop Screens

Dashboard Layout
dart
// lib/screens/student/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  final User user;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          CoinBalanceWidget(coins: user.coins), // Inspired by FlexyCoin
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: XP, Level, Streak
            _buildHeaderCard(user),
            
            SizedBox(height: 20),
            
            // Section 1: Subject Mastery Radar Chart
            Text('Subject Mastery', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 10),
            RadarChartWidget(masteryData: user.topicMastery),
            
            SizedBox(height: 20),
            
            // Section 2: Bloom Level Progress Bars
            Text('Bloom Level Progress', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 10),
            _buildBloomProgressBars(),
            
            SizedBox(height: 20),
            
            // Section 3: Quick Stats Cards (inspired by FlexyCoin dashboard)
            _buildQuickStatsCards(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'Clinic'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
  
  Widget _buildHeaderCard(User user) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Level ${user.level}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('${user.xp} XP / ${user.nextLevelXp} XP'),
                LinearProgressIndicator(value: user.xp / user.nextLevelXp),
              ],
            ),
            Column(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
                Text('${user.streak} day streak'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickStatsCards() {
    // Inspired by FlexyCoin's stat cards [page:3]
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Text('18', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Text('Quizzes Completed'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Text('82%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Text('Avg Score'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
Shop Screen
dart
// lib/screens/student/shop_screen.dart

class ShopScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clinic Shop'),
        actions: [CoinBalanceWidget(coins: userCoins)],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService().getClinicItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          
          List<ClinicItem> items = snapshot.data!.docs
              .map((doc) => ClinicItem.fromFirestore(doc))
              .toList();
          
          return GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ShopItemCard(item: items[index]);
            },
          );
        },
      ),
    );
  }
}

// lib/widgets/shop_item_card.dart

class ShopItemCard extends StatelessWidget {
  final ClinicItem item;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(item.imageUrl, fit: BoxFit.cover),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Text(item.name, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.price} 🪙', style: TextStyle(color: Colors.amber)),
                    ElevatedButton(
                      onPressed: () => _purchaseItem(context, item),
                      child: Text('Buy'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _purchaseItem(BuildContext context, ClinicItem item) async {
    try {
      await FirebaseService().purchaseItem(
        userId: currentUserId,
        itemId: item.id,
        price: item.price,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} purchased!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $e')),
      );
    }
  }
}
Key Takeaway: FlexyCoin's grid-based shop + coin balance display adapted for AGOOM's medical equipment shop.

5. Admin Panel (Question Management)
Inspired by Flutter Quiz Firebase's Admin Features

Question List Screen
dart
// lib/screens/admin/question_list_screen.dart

class QuestionListScreen extends StatefulWidget {
  @override
  _QuestionListScreenState createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  String? selectedTopic;
  int? selectedBloomLevel;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Question Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => QuestionEditorScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    hint: Text('Topic'),
                    value: selectedTopic,
                    items: ['cardiovascular', 'respiratory', 'gastrointestinal', 
                            'renal', 'endocrine', 'neurology']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedTopic = val),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<int>(
                    hint: Text('Bloom Level'),
                    value: selectedBloomLevel,
                    items: [1, 2, 3]
                        .map((l) => DropdownMenuItem(value: l, child: Text('Level $l')))
                        .toList(),
                    onChanged: (val) => setState(() => selectedBloomLevel = val),
                  ),
                ),
              ],
            ),
          ),
          
          // Question List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                
                List<Question> questions = snapshot.data!.docs
                    .map((doc) => Question.fromFirestore(doc))
                    .toList();
                
                return ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    Question q = questions[index];
                    return ListTile(
                      title: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${q.topic} | Bloom ${q.bloomLevel} | Difficulty ${q.difficulty}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editQuestion(q),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteQuestion(q.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('questions')
        .where('active', isEqualTo: true);
    
    if (selectedTopic != null) {
      query = query.where('topic', isEqualTo: selectedTopic);
    }
    if (selectedBloomLevel != null) {
      query = query.where('bloomLevel', isEqualTo: selectedBloomLevel);
    }
    
    return query.snapshots();
  }
}
Key Takeaway: Flutter Quiz Firebase's "admin panel to add/delete questions" adapted for AGOOM's multi-topic, multi-Bloom structure.

6. Dark/Light Mode Support
Inspired by FlexyCoin's Theme Switching

dart
// lib/utils/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF14B8A6), // Teal (from AGOOM spec)
    scaffoldBackgroundColor: Color(0xFFF8FAFC),
    cardColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF14B8A6),
      foregroundColor: Colors.white,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF14B8A6),
    scaffoldBackgroundColor: Color(0xFF0F172A), // Dark navy
    cardColor: Color(0xFF1E293B),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Colors.white,
    ),
  );
}

// In main.dart:
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // Auto-switch based on device setting
  home: LoginScreen(),
)
Key Takeaway: FlexyCoin's "Switch your screen from light to dark mode anytime" integrated into AGOOM with custom medical theme colors.

7. Complete Dependencies (pubspec.yaml)
text
name: agoom
description: Adaptive Gamified Oriented Medical-learning

dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  
  # State Management (choose one)
  provider: ^6.1.1  # OR get: ^4.6.6 (like FlexyCoin uses GetX)
  
  # Charts
  fl_chart: ^0.66.0  # For radar chart
  
  # UI
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1
  
  # Animations (for Bean character)
  lottie: ^3.0.0  # OR rive: ^0.12.4
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
8. Key Differences from Reference Projects
Feature	Reference Projects	AGOOM Adaptation
Learning Domain	Math, geometry, animals (Edutainment) 
​	Pathophysiology (medical education)
Adaptive Metric	Child performance (Edutainment) 
​	Bloom taxonomy + difficulty (1-5)
Subject Structure	4 subjects: NLP, ML, BDA, Blockchain (Flutter Quiz)	6 topics: Cardiovascular, Respiratory, Gastrointestinal, Renal, Endocrine, Neurology
Gamification Theme	Cryptocurrency dashboard (FlexyCoin)	Medical clinic with equipment shop
Admin Features	Basic add/delete (Flutter Quiz)	+ Analytics (error rates, topic performance, Bloom-level analysis)
Social Features	None	Optional post-MVP (leaderboards, study groups)
9. Implementation Roadmap for Antigravity
Phase 1: Core Architecture (Week 1)
Set up Flutter project structure (folders as described in Section 1)

Implement Firebase service layer (Section 3)

Create data models (Question, User, QuizSession, ClinicItem)

Phase 2: Quiz Engine (Week 2)
Implement adaptive engine (Section 2)

Build quiz flow UI:

Question screen with MCQ/True-False support

Immediate feedback screen (correct/incorrect + explanation)

Quiz summary screen (score, coins earned)

Test adaptive logic with dummy data

Phase 3: Student Features (Week 3)
Build dashboard screen (Section 4: radar chart, progress bars, stat cards)

Implement coin economy (earn coins per correct answer)

Build shop screen (grid of clinic items)

Build clinic view (2D layout showing purchased items - simple version)

Phase 4: Admin Panel (Week 4)
Build question management UI (Section 5: list, filters, CRUD)

Implement question editor (text, options, metadata fields)

Build basic analytics screen (question error rates)

Phase 5: Polish (Week 5)
Add Bean character widget (placeholder sprite initially)

Implement dark/light mode (Section 6)

Add onboarding flow

Test with 20-30 questions across 2-3 topics

10. Prompting Antigravity: Recommended Approach
Upload these files to Antigravity:

This document (AGOOM_Hybrid_Implementation_Guide.md)

AGOOM Complete Project Specification (your 11-section document)

Prompt:

text
I want to build AGOOM, a Flutter medical quiz app with adaptive learning + gamification.

I've attached:
1. AGOOM Complete Project Specification (full requirements)
2. AGOOM Hybrid Implementation Guide (architecture based on 3 reference Flutter projects)

The Hybrid Guide combines patterns from:
- Edutainment (adaptive quiz engine)
- Flutter Quiz Firebase (Firebase backend + admin panel)
- FlexyCoin (gamification UI: dashboard, shop, coins)

Your task:
1. Read both documents carefully
2. Create a Flutter project following the structure in Section 1 of the Hybrid Guide
3. Implement the adaptive engine from Section 2
4. Set up Firebase backend from Section 3
5. Build student dashboard + shop from Section 4
6. Build admin question management from Section 5
7. Add dark/light mode from Section 6

BEFORE CODING:
- Create a plan artifact showing:
  * Widget tree hierarchy for Dashboard, Quiz, Shop, Admin screens
  * Firebase security rules (Firestore)
  * Adaptive algorithm pseudocode with example scenarios
- Ask for my approval

After approval, implement Phase 1-2 first (Core Architecture + Quiz Engine).
Ask me before proceeding to Phase 3.
11. Expected Antigravity Output
After running this prompt, Antigravity should generate:

Plan Artifact (for your review):

Complete widget tree

Firebase schema diagram

Adaptive logic flowchart

Flutter Project with:

✅ Folder structure matching Section 1

✅ firebase_service.dart with CRUD + quiz methods

✅ adaptive_engine.dart with Bloom/difficulty logic

✅ Basic UI for dashboard, quiz, shop (material design)

✅ Admin panel for question management

✅ Dark/light mode support

Firebase Configuration Files:

firestore.rules (security rules)

firebase_options.dart (auto-generated by FlutterFire CLI)