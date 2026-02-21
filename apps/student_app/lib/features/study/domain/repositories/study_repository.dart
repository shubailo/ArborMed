import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/question.dart';

abstract class StudyRepository {
  Future<Either<Failure, Question>> getNextQuestion(String mode);
  Future<Either<Failure, void>> submitAnswer(String questionId, int quality);
}
