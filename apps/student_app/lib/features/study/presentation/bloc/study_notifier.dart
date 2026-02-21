import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/error/failures.dart';
import '../../data/datasources/study_remote_data_source.dart';
import '../../data/repositories/study_repository_impl.dart';
import '../../domain/repositories/study_repository.dart';

import '../../domain/usecases/get_next_question.dart';
import 'study_state.dart';
import '../../providers/study_providers.dart';

// Providers
final httpClientProvider = Provider((ref) => http.Client());

final studyRemoteDataSourceProvider = Provider<StudyRemoteDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return StudyRemoteDataSourceImpl(
    client: client,
    baseUrl:
        'http://localhost:3000', // Update with real URL for physical devices
  );
});

final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  final remote = ref.watch(studyRemoteDataSourceProvider);
  return StudyRepositoryImpl(remoteDataSource: remote);
});

final getNextQuestionUseCaseProvider = Provider((ref) {
  final repository = ref.watch(studyRepositoryProvider);
  return GetNextQuestionUseCase(repository);
});

final studyProvider = StateNotifierProvider<StudyNotifier, StudyState>((ref) {
  final getNextQuestion = ref.watch(getNextQuestionUseCaseProvider);
  final repository = ref.watch(studyRepositoryProvider);
  // Watch the provider directly inside the notifier creation or pass it
  final mode = ref.watch(studyModeProvider);
  return StudyNotifier(getNextQuestion, repository, mode);
});

// Notifier
class StudyNotifier extends StateNotifier<StudyState> {
  final GetNextQuestionUseCase _getNextQuestion;
  final StudyRepository _repository;
  final String _mode;

  StudyNotifier(this._getNextQuestion, this._repository, this._mode)
    : super(StudyInitial());

  Future<void> fetchNextQuestion() async {
    state = StudyLoading();
    final result = await _getNextQuestion(GetNextQuestionParams(mode: _mode));

    result.fold((failure) {
      if (failure is EmptyFailure) {
        state = StudyEmpty();
      } else {
        state = const StudyError('Failed to load question');
      }
    }, (question) => state = StudyLoaded(question));
  }

  Future<void> submitAnswer(String questionId, bool isCorrect) async {
    // Map bool to SM-2 quality (5 for correct, 0 for wrong)
    final quality = isCorrect ? 5 : 0;
    await _repository.submitAnswer(questionId, quality);
    await fetchNextQuestion();
  }
}
