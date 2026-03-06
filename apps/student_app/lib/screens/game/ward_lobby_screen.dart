import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/services/ward_provider.dart';
import 'package:arbor_med/widgets/cozy/cozy_button.dart';

class WardLobbyScreen extends StatefulWidget {
  const WardLobbyScreen({super.key});

  @override
  State<WardLobbyScreen> createState() => _WardLobbyScreenState();
}

class _WardLobbyScreenState extends State<WardLobbyScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wardProvider = Provider.of<WardProvider>(context);

    // Handle navigation based on state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (wardProvider.state == WardState.playing) {
        Navigator.of(context).pushReplacementNamed('/ward_round');
      }
      if (wardProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wardProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        wardProvider.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Wards'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            wardProvider.leaveWard();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: wardProvider.state == WardState.idle
            ? _buildIdleState(wardProvider)
            : _buildLobbyState(wardProvider),
      ),
    );
  }

  Widget _buildIdleState(WardProvider wardProvider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_hospital, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Collaborate on complex clinical cases with your peers.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 48),
          CozyButton(
            label: 'Create New Ward',
            onPressed: () => wardProvider.createWard('My Study Ward'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Ward Code',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 16),
              CozyButton(
                label: 'Join',
                onPressed: () {
                  if (_codeController.text.isNotEmpty) {
                    wardProvider.joinWard(_codeController.text);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLobbyState(WardProvider wardProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          wardProvider.wardName ?? 'Study Ward',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Code: ${wardProvider.currentWardCode}',
          style: const TextStyle(fontSize: 40, letterSpacing: 8, color: Colors.blue),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, size: 32),
            const SizedBox(width: 8),
            Text(
              '${wardProvider.userCount} / 4 Members Joined',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
        const SizedBox(height: 64),
        if (wardProvider.isHost)
          CozyButton(
            label: 'Start Ward Rounds',
            onPressed: () => wardProvider.startRound(),
          )
        else
          const Text('Waiting for the Attending (Host) to start...', style: TextStyle(fontStyle: FontStyle.italic)),
      ],
    );
  }
}
