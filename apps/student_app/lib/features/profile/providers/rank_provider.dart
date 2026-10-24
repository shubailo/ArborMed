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
      final response = await authProvider.apiService.post('/gamification/sync-rounds', {});
      
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

  int get requiredXpForCurrentRank {
    switch (currentRank) {
      case RankStatus.unmatched:
        return 0;
      case RankStatus.intern:
        return 300;
      case RankStatus.resident:
        return 700;
      case RankStatus.chief:
        return 1500;
      case RankStatus.attending:
        return 3000;
    }
  }

  int get requiredXpForNextRank {
    switch (currentRank) {
      case RankStatus.unmatched:
        return 300;
      case RankStatus.intern:
        return 700;
      case RankStatus.resident:
        return 1500;
      case RankStatus.chief:
        return 3000;
      case RankStatus.attending:
        return 3000;
    }
  }

  /// Calculates rank-up eligibility based on XP and clear record (no strikes)
  double get rankProgress {
    if (currentRank == RankStatus.attending) return 1.0;
    final xp = authProvider.user?.xp ?? 0;
    final prev = requiredXpForCurrentRank;
    final next = requiredXpForNextRank;
    if (next <= prev) return 1.0;
    return ((xp - prev) / (next - prev)).clamp(0.0, 1.0);
  }

  String get rankRequirement {
    if (currentRank == RankStatus.attending) return 'Top Clinical Rank Attained';
    final xp = authProvider.user?.xp ?? 0;
    final remaining = (requiredXpForNextRank - xp).clamp(0, 99999);
    return 'Earn $remaining more XP for next Rank';
  }
}
