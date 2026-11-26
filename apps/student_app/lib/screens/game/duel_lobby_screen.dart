import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/duel_provider.dart';
import '../../services/auth_provider.dart';
import '../../widgets/cozy/cozy_panel.dart';
import '../../widgets/cozy/cozy_button.dart';
import '../../generated/l10n/app_localizations.dart';
import 'duel_game_screen.dart';

class DuelLobbyScreen extends StatefulWidget {
  const DuelLobbyScreen({super.key});

  @override
  State<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends State<DuelLobbyScreen> {
  bool _openingMatch = false;
  bool _exiting = false;
  bool _joining = false;
  bool _left = false;
  int _joinAttempt = 0;
  bool get _current => mounted && ModalRoute.of(context)?.isCurrent == true;
  AppLocalizations get _strings =>
      AppLocalizations.of(context) ??
      lookupAppLocalizations(const Locale('en'));
  DuelProvider? _duel;
  int _selectedWager = 10;
  final List<int> _wagerPresets = [5, 10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    // Initialize the socket when entering the lobby
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _duel = context.read<DuelProvider>()..initialize();
    });
  }

  void _message(String text) {
    if (!_current) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _join() async {
    if (_joining || _exiting || !_current) return;
    final auth = context.read<AuthProvider>();
    final duel = context.read<DuelProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;
    final wager = _selectedWager;
    final attempt = ++_joinAttempt;
    setState(() => _joining = true);
    try {
      await auth.refreshUser();
      if (!_current ||
          attempt != _joinAttempt ||
          auth.user?.id != userId ||
          duel.state == DuelState.playing ||
          duel.state == DuelState.searching) {
        return;
      }
      if ((auth.user?.coins ?? 0) < wager) {
        _message(_strings.duelLowBalance);
        return;
      }
      duel.joinQueue(wager);
    } catch (_) {
      if (_current && attempt == _joinAttempt) {
        _message(_strings.duelRefreshFailed);
      }
    } finally {
      if (mounted && attempt == _joinAttempt) setState(() => _joining = false);
    }
  }

  Future<void> _refreshBalance(AuthProvider auth) async {
    try {
      await auth.refreshUser();
    } catch (_) {
      if (_current && !_left) _message(_strings.duelRefreshFailed);
    }
  }

  Future<void> _leave({required bool exitLobby}) async {
    if (_exiting || _openingMatch || !_current) return;
    final duel = context.read<DuelProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    _joinAttempt++;
    setState(() {
      _joining = false;
      _exiting = true;
    });
    try {
      final cancelled = await duel.leaveQueue();
      if (!mounted ||
          !_current ||
          _openingMatch ||
          duel.state == DuelState.playing) {
        return;
      }
      if (!cancelled) {
        _message(_strings.duelLeaveFailed);
        return;
      }
      if (exitLobby) {
        _left = true;
        Navigator.of(context).pop();
      }
      if (auth.user?.id == userId) unawaited(_refreshBalance(auth));
    } catch (_) {
      if (_current) _message(_strings.duelLeaveFailed);
    } finally {
      if (mounted && !_left) setState(() => _exiting = false);
    }
  }

  @override
  void dispose() {
    if (!_openingMatch &&
        !_exiting &&
        !_left &&
        _duel?.state == DuelState.searching) {
      unawaited(_duel!.leaveQueue().then<void>((_) {}, onError: (Object error) {
        debugPrint('Duel queue cleanup failed: ${error.runtimeType}');
      }));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duelProvider = context.watch<DuelProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final l10n = _strings;

    // If a match is found, navigate to the game screen automatically
    if (ModalRoute.isCurrentOf(context) == true &&
        duelProvider.state == DuelState.playing &&
        !_openingMatch) {
      _openingMatch = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_current || duelProvider.state != DuelState.playing) {
          _openingMatch = false;
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DuelGameScreen()),
        );
      });
    }

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave(exitLobby: true);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.duelArena),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _leave(exitLobby: true),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(context, user?.coins ?? 0),
                    const SizedBox(height: 32),
                    if (duelProvider.state == DuelState.searching)
                      _buildSearchingState(context, duelProvider)
                    else
                      _buildLobbyState(context, user?.coins ?? 0),
                    if (duelProvider.state == DuelState.error)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          duelProvider.errorMessage ?? l10n.error,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildHeader(BuildContext context, int coins) {
    return Column(
      children: [
        Icon(Icons.workspace_premium, size: 64, color: Color(0xFFC48B76)),
        const SizedBox(height: 16),
        Text(
          _strings.duelArena.toUpperCase(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.medical_services_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                _strings.duelWalletAmount(coins),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLobbyState(BuildContext context, int userCoins) {
    return CozyPanel(
      title: _strings.duelSelectWager,
      child: Column(
        children: [
          Text(_strings.duelChooseWager),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _wagerPresets.map((wager) {
              final isSelected = _selectedWager == wager;
              final canAfford = userCoins >= wager;

              return ChoiceChip(
                label: Text("$wager 🩺"),
                selected: isSelected,
                onSelected: canAfford && !_joining && !_exiting
                    ? (selected) {
                        setState(() => _selectedWager = wager);
                      }
                    : null,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                disabledColor: Colors.grey.shade200,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          CozyButton(
            label: _strings.duelFindMatch,
            isLoading: _joining,
            onPressed: !_exiting && !_joining && userCoins >= _selectedWager
                ? _join
                : null,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingState(BuildContext context, DuelProvider duelProvider) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          _strings.duelSearching,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(_strings.duelWagerAmount(duelProvider.currentWager)),
        const SizedBox(height: 32),
        CozyButton(
          label: _strings.cancel,
          onPressed: _exiting ? null : () => _leave(exitLobby: false),
          variant: CozyButtonVariant.secondary,
        ),
      ],
    );
  }
}
