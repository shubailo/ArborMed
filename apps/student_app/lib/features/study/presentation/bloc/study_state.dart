import 'package:equatable/equatable.dart';
import '../domain/entities/question.dart';

abstract class StudyState extends Equatable {
  const StudyState();

  @override
  List<Object?> get props => [];
}

class StudyInitial extends StudyState {}

class StudyLoading extends StudyState {}

class StudyLoaded extends StudyState {
  final Question question;

  const StudyLoaded(this.question);

  @override
  List<Object?> get props => [question];
}

class StudyError extends StudyState {
  final String message;

  const StudyError(this.message);

  @override
  List<Object?> get props => [message];
}
