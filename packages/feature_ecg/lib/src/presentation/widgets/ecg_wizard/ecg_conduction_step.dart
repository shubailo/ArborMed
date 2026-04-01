import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';

class ECGConductionStep extends StatelessWidget {
  final Map<String, dynamic> userFindings;
  final Function(String, dynamic) onUpdate;

  const ECGConductionStep({
    super.key,
    required this.userFindings,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final List<String> intervalOpts = ['Normal', 'Prolonged', 'Short'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(palette, 'CONDUCTION INTERVALS'),
          const SizedBox(height: 24),

          _buildIntervalSelector(
            palette,
            'PR Interval',
            userFindings['pr_interval'] ?? 'Normal',
            (val) => onUpdate('pr_interval', val),
            intervalOpts,
          ),

          const SizedBox(height: 32),

          _buildIntervalSelector(
            palette,
            'QRS Duration',
            userFindings['qrs_duration'] ?? 'Normal',
            (val) => onUpdate('qrs_duration', val),
            intervalOpts,
          ),

          const SizedBox(height: 32),

          _buildIntervalSelector(
            palette,
            'QT Interval',
            userFindings['qt_interval'] ?? 'Normal',
            (val) => onUpdate('qt_interval', val),
            intervalOpts,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(CozyPalette palette, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: palette.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildIntervalSelector(
    CozyPalette palette,
    String label,
    String selected,
    Function(String) onSelect,
    List<String> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: options.map((opt) {
            final isSelected = selected == opt;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(opt),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? palette.primary : palette.paperWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? palette.primary : palette.textSecondary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      opt,
                      style: TextStyle(
                        color: isSelected ? Colors.white : palette.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
