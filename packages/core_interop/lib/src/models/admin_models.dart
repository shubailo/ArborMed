import 'package:meta/meta.dart';

@immutable
class AdminQuestion {
  final int id;
  final String? text;
  final String? questionTextHu;
  final dynamic options;
  final dynamic content;
  final dynamic correctAnswer;
  final String? explanation;
  final String? explanationHu;
  final int topicId;
  final String? topicNameEn;
  final String? topicNameHu;
  final int bloomLevel;
  final String? type;
  final int attempts;
  final double successRate;
  final int reportCount;

  const AdminQuestion({
    required this.id,
    this.text,
    this.questionTextHu,
    required this.options,
    this.content,
    required this.correctAnswer,
    this.explanation,
    this.explanationHu,
    required this.topicId,
    this.topicNameEn,
    this.topicNameHu,
    required this.bloomLevel,
    this.type,
    this.attempts = 0,
    this.successRate = 0.0,
    this.reportCount = 0,
  });

  factory AdminQuestion.fromJson(Map<String, dynamic> json) {
    return AdminQuestion(
      id: json['id'],
      text: json['text'] ?? json['question_text_en'] ?? '',
      questionTextHu: json['question_text_hu'],
      options: json['options'],
      content: json['content'],
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'] ?? json['explanation_en'],
      explanationHu: json['explanation_hu'],
      topicId: json['topic_id'] ?? 0,
      topicNameEn: json['topic_name'] ?? json['name_en'],
      topicNameHu: json['topic_name_hu'] ?? json['name_hu'],
      bloomLevel: json['bloom_level'] ?? 1,
      type: json['type'] ?? 'single_choice',
      attempts: json['attempts'] ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0.0,
      reportCount: json['report_count'] ?? 0,
    );
  }
}

@immutable
class SubjectPerformance {
  final int avgScore;
  final int totalQuestions;
  final int correctQuestions;
  final int avgTimeMs;

  const SubjectPerformance({
    required this.avgScore,
    required this.totalQuestions,
    required this.correctQuestions,
    required this.avgTimeMs,
  });

  factory SubjectPerformance.fromJson(Map<String, dynamic> json) {
    return SubjectPerformance(
      avgScore: json['avg_score'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      correctQuestions: json['correct_questions'] ?? 0,
      avgTimeMs: json['avg_time_ms'] ?? 0,
    );
  }
}

@immutable
class UserPerformance {
  final int id;
  final String email;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final SubjectPerformance pathophysiology;
  final SubjectPerformance pathology;
  final SubjectPerformance microbiology;
  final SubjectPerformance pharmacology;
  final SubjectPerformance ecg;
  final SubjectPerformance cases;

  final int? assignedSubjectId;
  final String? assignedSubjectName;
  final int? questionsUploaded;

  const UserPerformance({
    required this.id,
    required this.email,
    required this.createdAt,
    this.lastActivity,
    required this.pathophysiology,
    required this.pathology,
    required this.microbiology,
    required this.pharmacology,
    required this.ecg,
    required this.cases,
    this.assignedSubjectId,
    this.assignedSubjectName,
    this.questionsUploaded,
  });

  factory UserPerformance.fromJson(Map<String, dynamic> json) {
    SubjectPerformance parseSubject(String prefix) {
      return SubjectPerformance(
        avgScore: json['${prefix}_avg'] ?? 0,
        totalQuestions: json['${prefix}_total'] ?? 0,
        correctQuestions: json['${prefix}_correct'] ?? 0,
        avgTimeMs: json['${prefix}_time'] ?? 0,
      );
    }

    return UserPerformance(
      id: json['id'],
      email: json['email'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
      pathophysiology: parseSubject('pathophysiology'),
      pathology: parseSubject('pathology'),
      microbiology: parseSubject('microbiology'),
      pharmacology: parseSubject('pharmacology'),
      ecg: parseSubject('ecg'),
      cases: parseSubject('cases'),
      assignedSubjectId: json['assigned_subject_id'],
      assignedSubjectName: json['assigned_subject_name'],
      questionsUploaded: json['questions_uploaded'],
    );
  }
}

@immutable
class QuestionStats {
  final String questionId;
  final String questionText;
  final String topicSlug;
  final int bloomLevel;
  final int totalAttempts;
  final int correctCount;
  final int avgTimeMs;
  final int correctPercentage;

  const QuestionStats({
    required this.questionId,
    required this.questionText,
    required this.topicSlug,
    required this.bloomLevel,
    required this.totalAttempts,
    required this.correctCount,
    required this.avgTimeMs,
    required this.correctPercentage,
  });

  factory QuestionStats.fromJson(Map<String, dynamic> json) {
    return QuestionStats(
      questionId: json['question_id']?.toString() ?? '',
      questionText: json['question_text'] ?? '',
      topicSlug: json['topic_slug'] ?? '',
      bloomLevel: int.tryParse(json['bloom_level']?.toString() ?? '1') ?? 1,
      totalAttempts: int.tryParse(json['total_attempts']?.toString() ?? '0') ?? 0,
      correctCount: int.tryParse(json['correct_count']?.toString() ?? '0') ?? 0,
      avgTimeMs: int.tryParse(json['avg_time_ms']?.toString() ?? '0') ?? 0,
      correctPercentage: int.tryParse(json['correct_percentage']?.toString() ?? '0') ?? 0,
    );
  }
}

@immutable
class UserHistoryEntry {
  final int id;
  final DateTime createdAt;
  final bool isCorrect;
  final int responseTimeMs;
  final String questionText;
  final int bloomLevel;
  final String sectionName;
  final String subjectName;
  final String subjectSlug;

  const UserHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.questionText,
    required this.bloomLevel,
    required this.sectionName,
    required this.subjectName,
    required this.subjectSlug,
  });

  factory UserHistoryEntry.fromJson(Map<String, dynamic> json) {
    return UserHistoryEntry(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      isCorrect: json['is_correct'] ?? false,
      responseTimeMs: json['response_time_ms'] ?? 0,
      questionText: json['question_text_en'] ?? '',
      bloomLevel: json['bloom_level'] ?? 1,
      sectionName: json['section_name'] ?? '',
      subjectName: json['subject_name'] ?? '',
      subjectSlug: json['subject_slug'] ?? '',
    );
  }
}
