import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Models the state of an ECG practice session.
class PracticeState {
  final int currentCaseIndex;
  final int totalCases;
  final int xpEarned;
  final bool isCompleted;

  const PracticeState({
    required this.currentCaseIndex,
    required this.totalCases,
    required this.xpEarned,
    required this.isCompleted,
  });

  PracticeState copyWith({
    int? currentCaseIndex,
    int? totalCases,
    int? xpEarned,
    bool? isCompleted,
  }) {
    return PracticeState(
      currentCaseIndex: currentCaseIndex ?? this.currentCaseIndex,
      totalCases: totalCases ?? this.totalCases,
      xpEarned: xpEarned ?? this.xpEarned,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Service managing the logic for ECG practice mode.
class PracticeService extends ChangeNotifier {
  final Logger _logger;
  
  PracticeState _state;

  PracticeService({Logger? logger}) 
      : _logger = logger ?? Logger(),
        _state = const PracticeState(
          currentCaseIndex: 0,
          totalCases: 5,
          xpEarned: 0,
          isCompleted: false,
        );

  PracticeState get state => _state;

  /// Start or restart a practice session
  void startSession({int totalCases = 5}) {
    _logger.i('Starting practice session with $totalCases cases');
    _state = PracticeState(
      currentCaseIndex: 0,
      totalCases: totalCases,
      xpEarned: 0,
      isCompleted: false,
    );
    notifyListeners();
  }

  /// Advance to the next case (if available) and award XP
  void completeCurrentCase({int xpReward = 10}) {
    if (_state.isCompleted) return;

    final newIndex = _state.currentCaseIndex + 1;
    final isDone = newIndex >= _state.totalCases;

    _logger.d('Completed case ${_state.currentCaseIndex}. +$xpReward XP. done: $isDone');

    _state = _state.copyWith(
      currentCaseIndex: isDone ? _state.currentCaseIndex : newIndex,
      xpEarned: _state.xpEarned + xpReward,
      isCompleted: isDone,
    );
    notifyListeners();
  }
}
