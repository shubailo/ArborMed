import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import 'api_service.dart';

class SubjectMastery {
  final String subject;
  final String slug;
  final int totalAnswered;
  final int correctAnswered;
  final int masteryPercent;

  SubjectMastery({
    required this.subject,
    required this.slug,
    required this.totalAnswered,
    required this.correctAnswered,
    required this.masteryPercent,
  });

  factory SubjectMastery.fromJson(Map<String, dynamic> json) {
    return SubjectMastery(
      subject: json['subject'] ?? 'Unknown',
      slug: json['slug'] ?? '',
      totalAnswered: int.tryParse(json['total_answered']?.toString() ?? '0') ?? 0,
      correctAnswered: int.tryParse(json['correct_answered']?.toString() ?? '0') ?? 0,
      masteryPercent: int.tryParse(json['mastery_percent']?.toString() ?? '0') ?? 0,
    );
  }
}

class ActivityData {
  final DateTime date;
  final int count;
  final int correctCount;

  ActivityData({required this.date, required this.count, required this.correctCount});

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      date: DateTime.parse(json['date']),
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      correctCount: int.tryParse(json['correct_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class StatsProvider with ChangeNotifier {
  final AuthProvider authProvider;
  List<SubjectMastery> _subjectMastery = [];
  List<ActivityData> _activity = [];
  bool _isLoading = false;

  StatsProvider(this.authProvider);

  List<SubjectMastery> get subjectMastery => _subjectMastery;
  List<ActivityData> get activity => _activity;
  bool get isLoading => _isLoading;

  final Map<String, List<Map<String, dynamic>>> _sectionMastery = {};
  Map<String, List<Map<String, dynamic>>> get sectionMastery => _sectionMastery;

  String get _baseUrl => '${ApiService.baseUrl}/stats';

  Future<void> fetchSummary() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/summary'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _subjectMastery = data.map((item) => SubjectMastery.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActivity({String timeframe = 'week', DateTime? anchorDate}) async {
    try {
      String url = '$_baseUrl/activity?timeframe=$timeframe';
      if (anchorDate != null) {
        // Format YYYY-MM-DD
        String dateStr = anchorDate.toIso8601String().split('T')[0];
        url += '&anchorDate=$dateStr';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _activity = data.map((item) => ActivityData.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching activity: $e');
    }
  }

  Future<void> fetchSubjectDetail(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subject/$slug'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _sectionMastery[slug] = data.cast<Map<String, dynamic>>();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching subject detail: $e');
    }
  }
}
