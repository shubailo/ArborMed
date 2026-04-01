import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:core_interop/core_interop.dart';

class ECGHistoryStep extends StatelessWidget {
  final ECGCase ecgCase;

  const ECGHistoryStep({super.key, required this.ecgCase});

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    // Extract clinical history from findings
    final history = ecgCase.findings['history'] ?? 'No history provided.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinical Context Card
          _buildContextCard(palette, history),
          
          const SizedBox(height: 32),

          // ECG Image (Placeholder for now)
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: palette.paperWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.textSecondary.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Full view button (placeholder)
                  const Center(
                    child: Icon(Icons.show_chart, size: 64, color: Colors.blue),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      onPressed: () {},
                      backgroundColor: palette.primary,
                      child: const Icon(Icons.fullscreen, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Analyze the waveform above before proceeding to interpretation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextCard(CozyPalette palette, String history) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: palette.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'PATIENT HISTORY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: palette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            history,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
