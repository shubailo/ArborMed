import 'package:flutter/foundation.dart';

class QuestionReport {
  final int id;
  final int questionId;
  final int userId;
  final String? reporterEmail;
  final String reasonCategory;
  final String? description;
  final String status; // 'pending', 'resolved', 'ignored'
  final String? adminNotes;
  final DateTime createdAt;

  QuestionReport({
    required this.id,
    required this.questionId,
    required this.userId,
    this.reporterEmail,
    required this.reasonCategory,
    this.description,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });

  factory QuestionReport.fromJson(Map<String, dynamic> json) {
    try {
      return QuestionReport(
        id: json['id'],
        questionId: json['question_id'],
        userId: json['user_id'],
        reporterEmail: json['reporter_email'],
        reasonCategory: json['reason_category'],
        description: json['description'],
        status: json['status'],
        adminNotes: json['admin_notes'],
        createdAt: DateTime.parse(json['created_at']),
      );
    } catch (e) {
      debugPrint('Error parsing QuestionReport ID ${json['id']}: $e');
      rethrow;
    }
  }
}
