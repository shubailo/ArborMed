import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/study_repository.dart';
import '../datasources/study_remote_data_source.dart';

class StudyRepositoryImpl implements StudyRepository {
  final StudyRemoteDataSource remoteDataSource;
  // TODO: Add LocalDataSource for caching logic

  StudyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Question>> getNextQuestion() async {
    try {
      // Logic: Try remote first (minimal API style)
      final remoteQuestion = await remoteDataSource.getNextQuestion(
        'med-uni-01',
      );
      return Right(remoteQuestion);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> submitAnswer(
    String questionId,
    int quality,
  ) async {
    try {
      await remoteDataSource.submitAnswer(questionId, quality);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
