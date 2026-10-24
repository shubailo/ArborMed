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
  int _selectedWager = 10;
  final List<int> _wagerPresets = [5, 10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    // Initialize the socket when entering the lobby
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DuelProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final duelProvider = context.watch<DuelProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final l10n = AppLocalizations.of(context);

    // If a match is found, navigate to the game screen automatically
    if (duelProvider.state == DuelState.playing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DuelGameScreen()),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.duelArena ?? 'Duel Arena'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (duelProvider.state == DuelState.searching) {
              duelProvider.leaveQueue();
              context.read<AuthProvider>().refreshUser();
            } else {
              duelProvider.reset();
            }
            Navigator.pop(context);
          },
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
                  _buildLobbyState(context, duelProvider, user?.coins ?? 0),
                
                if (duelProvider.state == DuelState.error)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      duelProvider.errorMessage ?? 'Error occurred',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int coins) {
    return Column(
      children: [
        Icon(Icons.workspace_premium, size: 64, color: Color(0xFFC48B76)),
        const SizedBox(height: 16),
        Text(
          "DUEL ARENA",
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
                "$coins Stethoscopes",
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

  Widget _buildLobbyState(BuildContext context, DuelProvider duelProvider, int userCoins) {
    return CozyPanel(
      title: "Select Wager",
      child: Column(
        children: [
          const Text("Choose your bet for the knowledge battle:"),
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
                onSelected: canAfford ? (selected) {
                  setState(() => _selectedWager = wager);
                } : null,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                disabledColor: Colors.grey.shade200,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          CozyButton(
            label: "FIND MATCH",
            onPressed: userCoins >= _selectedWager 
              ? () async {
                  duelProvider.joinQueue(_selectedWager);
                  // Refresh wallet balance so deduction shows
                  await context.read<AuthProvider>().refreshUser();
                }
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
          "Searching for opponent...",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text("Wager: ${duelProvider.currentWager} 🩺"),
        const SizedBox(height: 32),
        CozyButton(
          label: "CANCEL",
          onPressed: () async {
            duelProvider.leaveQueue();
            await context.read<AuthProvider>().refreshUser();
          },
          variant: CozyButtonVariant.secondary,
        ),
      ],
    );
  }
}
