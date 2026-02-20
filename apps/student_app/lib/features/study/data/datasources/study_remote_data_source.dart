import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question_model.dart';

abstract class StudyRemoteDataSource {
  Future<QuestionModel> getNextQuestion(String orgId);
  Future<void> submitAnswer(String questionId, int quality);
}

class StudyRemoteDataSourceImpl implements StudyRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  StudyRemoteDataSourceImpl({required this.client, required this.baseUrl});

  @override
  Future<QuestionModel> getNextQuestion(String orgId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/study/next?orgId=$orgId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return QuestionModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Server Error');
    }
  }

  @override
  Future<void> submitAnswer(String questionId, int quality) async {
    final response = await client.post(
      Uri.parse('$baseUrl/study/answer'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'questionId': questionId,
        'quality': quality,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Server Error');
    }
  }
}
