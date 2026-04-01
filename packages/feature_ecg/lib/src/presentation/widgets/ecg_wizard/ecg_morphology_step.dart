import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';

class ECGMorphologyStep extends StatelessWidget {
  final Map<String, dynamic> userFindings;
  final Function(String, dynamic) onUpdate;

  const ECGMorphologyStep({
    super.key,
    required this.userFindings,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(palette, 'WAVEFORM MORPHOLOGY'),
          const SizedBox(height: 24),

          _buildMorphologySelector(
            palette,
            'P-Wave Morphology',
            userFindings['p_morph'] ?? 'Normal',
            (val) => onUpdate('p_morph', val),
            ['Normal', 'Peaked', 'Bifid', 'Inverted', 'Absent', 'Sawtooth'],
          ),

          const SizedBox(height: 32),

          _buildMorphologySelector(
            palette,
            'Ventricular Hypertrophy',
            userFindings['hypertrophy'] ?? 'None',
            (val) => onUpdate('hypertrophy', val),
            ['None', 'LVH', 'RVH', 'Bi-Ventricular'],
          ),

          const SizedBox(height: 32),

          _buildMorphologySelector(
            palette,
            'ST Segment / Ischemia',
            userFindings['ischemia'] ?? 'None',
            (val) => onUpdate('ischemia', val),
            ['None', 'ST Elevation', 'ST Depression', 'Hyperacute T'],
          ),

          const SizedBox(height: 32),

          _buildMorphologySelector(
            palette,
            'T-Wave Morphology',
            userFindings['t_wave'] ?? 'Normal',
            (val) => onUpdate('t_wave', val),
            ['Normal', 'Inverted', 'Flattened', 'Biphasic', 'Peaked'],
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

  Widget _buildMorphologySelector(
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected == opt;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? palette.primary : palette.paperWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? palette.primary : palette.textSecondary.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? Colors.white : palette.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
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
