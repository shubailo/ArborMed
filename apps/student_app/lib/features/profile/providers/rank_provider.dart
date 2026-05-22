import 'package:flutter/foundation.dart';
import '../../../services/auth_provider.dart';
import '../models/rank_status.dart';

class RankProvider with ChangeNotifier {
  final AuthProvider authProvider;

  RankProvider(this.authProvider);

  RankStatus get currentRank => RankStatus.fromString(authProvider.user?.rank);

  int get malpracticeStrikes => authProvider.user?.malpracticeStrikes ?? 0;

  bool get isOnProbation => malpracticeStrikes >= 3;

  static const int dailyRoundsGoal = 10;

  /// Logic to check if user has performed "Daily Rounds" today
  /// Condition A: Correctly answer 10 questions today
  bool hasReachedRoundsThreshold(int correctAnswersToday) {
    return correctAnswersToday >= dailyRoundsGoal;
  }

  bool get hasDoneRoundsToday {
    final lastRounds = authProvider.user?.lastRoundsDate;
    if (lastRounds == null) return false;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    return lastRounds == today;
  }

  /// Triggered from the Mission Control dashboard to "complete rounds"
  /// once the threshold is reached.
  Future<bool> syncCompletedRounds() async {
    try {
      final response =
          await authProvider.apiService.post('/gamification/sync-rounds', {});

      if (response['status'] == 'success') {
        // Refresh profile to get updated strikes and last_rounds_date
        await authProvider.refreshUser();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error syncing rounds: $e");
      return false;
    }
  }

  Future<void> fetchStatus() async {
    try {
      await authProvider.refreshUser();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error fetching clinical status: $e");
    }
  }

  /// Calculates rank-up eligibility based on XP and clear record (no strikes)
  double get rankProgress {
    // Example: Each rank requires 1000 XP
    final xp = authProvider.user?.xp ?? 0;
    return (xp % 1000) / 1000.0;
  }

  String get rankRequirement {
    if (currentRank == RankStatus.chief) return 'Max Rank Reached';
    return 'Earn ${1000 - ((authProvider.user?.xp ?? 0) % 1000)} more XP for next Rank';
  }
}
