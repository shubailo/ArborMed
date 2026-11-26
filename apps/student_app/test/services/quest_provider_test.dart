import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arbor_med/core/models/user.dart';
import 'package:arbor_med/features/profile/models/quest.dart';
import 'package:arbor_med/features/profile/providers/quest_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/auth_provider.dart';

class QuestApi extends Fake implements ApiService {
  bool claimed = false;
  Completer<dynamic>? pending;
  @override
  Future<dynamic> get(String endpoint) async => {
        'date': DateTime.now().toUtc().toIso8601String().substring(0, 10),
        'quests': [
          {
            'id': 'daily_3',
            'type': 'perfectScore',
            'title': 'Perfect',
            'description': 'Five correct',
            'rewardTokens': 30,
            'targetCount': 5,
            'currentCount': 5,
            'status': claimed ? 'claimed' : 'completed'
          }
        ]
      };

  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    expect(data['questId'], 'daily_3');
    claimed = true;
    return pending?.future ??
        Future.value({'newBalance': 100, 'awardedTokens': 30});
  }
}

class QuestAuth extends ChangeNotifier implements AuthProvider {
  @override
  final QuestApi apiService = QuestApi();
  int id = 1;
  int? balance;
  @override
  User get user => User.fromJson({'id': id});
  @override
  void updateCoinBalance(int value) => balance = value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the quest tab shows and claims a server-verified perfect round',
      () async {
    final auth = QuestAuth();
    final provider = QuestProvider(auth);
    await provider.fetchQuests();
    expect(provider.quests.single.status, QuestStatus.completed);
    expect(await provider.claimQuest('daily_3'), 30);
    expect(auth.balance, 100);
    expect(provider.quests.single.status, QuestStatus.claimed);
  });

  test('a delayed claim cannot change a different account balance', () async {
    final auth = QuestAuth();
    final provider = QuestProvider(auth);
    await provider.fetchQuests();
    auth.apiService.pending = Completer<dynamic>();
    final claim = provider.claimQuest('daily_3');
    auth.id = 2;
    expect(provider.quests, isEmpty);
    auth.apiService.pending!.complete({'newBalance': 100, 'awardedTokens': 30});
    expect(await claim, 0);
    expect(auth.balance, isNull);
  });
}
