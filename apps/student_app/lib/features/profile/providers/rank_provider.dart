import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../../services/auth_provider.dart';
import '../models/rank_status.dart';

typedef _Standing = ({
  RankStatus rank,
  int strikes,
  int? progress,
  int goal,
  bool done,
  String day
});

class RankProvider extends ChangeNotifier with WidgetsBindingObserver {
  RankProvider(this.authProvider, {DateTime Function()? now})
      : _now = now ?? DateTime.now {
    authProvider.addListener(_authChanged);
    WidgetsBinding.instance.addObserver(this);
    _authChanged();
  }
  final AuthProvider authProvider;
  final DateTime Function() _now;
  int? _owner;
  int _session = -1;
  int _request = 0;
  bool _disposed = false;
  bool _failed = false;
  Future<bool>? _sync;
  Future<bool>? _read;
  _Standing? _standing;
  String? _loadedOn;
  Timer? _midnight;
  static const dailyRoundsGoal = 10;
  String get _today => _now().toUtc().toIso8601String().split('T').first;
  _Standing? get _current => _loadedOn == _today ? _standing : null;
  RankStatus get currentRank =>
      _current?.rank ?? RankStatus.fromString(authProvider.user?.rank);
  int get malpracticeStrikes =>
      _current?.strikes ?? authProvider.user?.malpracticeStrikes ?? 0;
  int get xp => authProvider.user?.xp ?? 0;
  bool get isOnProbation => malpracticeStrikes >= 3;
  bool get hasDoneRoundsToday =>
      _current?.done ?? authProvider.user?.completedRoundsOn(_now()) ?? false;
  int? get roundsProgress => _current?.progress;
  int get roundsGoal => _current?.goal ?? dailyRoundsGoal;
  bool get isSyncing => _sync != null;
  bool get statusFailed => _failed;

  void _authChanged() {
    final owner = authProvider.user?.id;
    final session = authProvider.sessionRevision;
    if (_owner != owner || _session != session) {
      _owner = owner;
      _session = session;
      _reset();
      _scheduleMidnight();
      if (owner != null) {
        scheduleMicrotask(() {
          if (!_disposed && _owner == owner && _session == session) {
            fetchStatus();
          }
        });
      }
    }
    notifyListeners();
  }

  bool _owns(int ticket) =>
      !_disposed &&
      ticket == _request &&
      _owner == authProvider.user?.id &&
      _session == authProvider.sessionRevision;

  void _reset() {
    _request++;
    _sync = null;
    _read = null;
    _standing = null;
    _failed = false;
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    if (_owner == null) return;
    final utc = _now().toUtc();
    _midnight = Timer(
        DateTime.utc(utc.year, utc.month, utc.day + 1).difference(utc), () {
      _reset();
      _scheduleMidnight();
      fetchStatus();
      notifyListeners();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _owner != null) {
      _scheduleMidnight();
      fetchStatus();
    }
  }

  Future<void> fetchStatus() async {
    if (_disposed || _owner == null) return;
    await (_sync ?? (_read ??= _load(false)));
  }

  Future<bool> syncCompletedRounds() {
    if (_disposed || _owner == null) return Future.value(false);
    if (_sync != null) return _sync!;
    _read = null;
    final pending = _load(true);
    _sync = pending;
    notifyListeners();
    return pending;
  }

  Future<bool> _load(bool complete) async {
    final ticket = ++_request;
    final today = _today;
    final expected = _current?.day;
    _failed = false;
    // Set the pending future before even a synchronous transport failure.
    await Future<void>.value();
    if (!_owns(ticket)) return false;
    try {
      final api = authProvider.apiService;
      final response = complete
          ? await api.post('/gamification/sync-rounds',
              {if (expected != null) 'studyDay': expected})
          : await api.get('/gamification/status');
      if (!_owns(ticket) || today != _today) return false;
      final standing = _parse(response, today);
      _loadedOn = today;
      _standing = standing;
      return standing.done;
    } catch (error) {
      if (_owns(ticket)) {
        _failed = true;
        debugPrint('Clinical standing request failed: ${error.runtimeType}');
      }
      return false;
    } finally {
      if (_owns(ticket)) {
        if (complete) {
          _sync = null;
        } else {
          _read = null;
        }
        notifyListeners();
      }
    }
  }

  static _Standing _parse(dynamic response, String today) {
    final data = response is Map ? response['data'] : null;
    if (data is! Map ||
        !(const {'success', 'incomplete'}.contains(response['status'])) ||
        data['rank'] is! String ||
        data['malpracticeStrikes'] is! int ||
        (data['malpracticeStrikes'] as int) < 0) {
      throw const FormatException('Invalid clinical standing');
    }
    final day = data['studyDay'] ?? today;
    if (day is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) {
      throw const FormatException('Invalid study day');
    }
    final goal = data['roundsGoal'] ?? dailyRoundsGoal;
    final progress = data['roundsProgress'];
    final completed = data['roundsCompleted'] ??
        (DateTime.tryParse(data['lastRoundsDate']?.toString() ?? '')
                ?.toUtc()
                .toIso8601String()
                .split('T')
                .first ==
            day);
    if (response['status'] == 'incomplete' && completed == true) {
      throw const FormatException('Conflicting completion status');
    }
    if (goal is! int ||
        goal <= 0 ||
        (progress != null &&
            (progress is! int || progress < 0 || progress > goal)) ||
        completed is! bool) {
      throw const FormatException('Invalid daily rounds');
    }
    return (
      rank: RankStatus.fromString(data['rank']),
      strikes: data['malpracticeStrikes'] as int,
      progress: progress as int?,
      goal: goal,
      done: completed,
      day: day
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _midnight?.cancel();
    authProvider.removeListener(_authChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
