class SubjectPerformance {
  final int avgScore;
  final int totalQuestions;
  final int correctQuestions;
  final int avgTimeMs;

  SubjectPerformance({
    required this.avgScore,
    required this.totalQuestions,
    required this.correctQuestions,
    required this.avgTimeMs,
  });
}

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

  // Admin-specific fields
  final int? assignedSubjectId;
  final String? assignedSubjectName;
  final int? questionsUploaded;

  UserPerformance({
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
