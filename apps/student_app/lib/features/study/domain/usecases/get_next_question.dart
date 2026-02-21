import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import 'package:equatable/equatable.dart';
import '../entities/question.dart';
import '../repositories/study_repository.dart';

class GetNextQuestionParams extends Equatable {
  final String mode;

  const GetNextQuestionParams({this.mode = 'NORMAL'});

  @override
  List<Object> get props => [mode];
}

class GetNextQuestionUseCase
    implements UseCase<Question, GetNextQuestionParams> {
  final StudyRepository repository;

  GetNextQuestionUseCase(this.repository);

  @override
  Future<Either<Failure, Question>> call(GetNextQuestionParams params) async {
    return await repository.getNextQuestion(params.mode);
  }
}
