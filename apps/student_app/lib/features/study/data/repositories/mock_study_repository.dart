import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/study_repository.dart';

class MockStudyRepository implements StudyRepository {
  @override
  Future<Either<Failure, Question>> getNextQuestion(String mode) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(
      Question(
        id: 'mock-1',
        topicId: 'cardiology',
        bloomLevel: 1,
        difficulty: 1,
        content:
            'Mock Question: What is the primary function of the mitral valve?',
        explanation: 'Explanation goes here.',
        options: [
          AnswerOption(id: '1', text: 'Option A', isCorrect: true),
          AnswerOption(id: '2', text: 'Option B', isCorrect: false),
        ],
      ),
    );
  }

  @override
  Future<Either<Failure, void>> submitAnswer(
    String questionId,
    int quality,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const Right(null);
  }
}
