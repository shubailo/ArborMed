class Report {
  final int id;
  final int questionId;
  final int userId;
  final String reasonCategory;
  final String description;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final String? reporterEmail;

  Report({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.reasonCategory,
    required this.description,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    this.reporterEmail,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      questionId: json['question_id'],
      userId: json['user_id'],
      reasonCategory: json['reason_category'] ?? 'other',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      adminNotes: json['admin_notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      reporterEmail: json['reporter_email'],
    );
  }
}
