import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/question.dart';
import '../repositories/study_repository.dart';

class GetNextQuestionUseCase implements UseCase<Question, NoParams> {
  final StudyRepository repository;

  GetNextQuestionUseCase(this.repository);

  @override
  Future<Either<Failure, Question>> call(NoParams params) async {
    return await repository.getNextQuestion();
  }
}
