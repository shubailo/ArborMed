import 'package:flutter/material.dart';
import '../../../theme/cozy_theme.dart';
import '../providers/ecg_wizard_state.dart';

class MorphologyPage extends StatelessWidget {
  final String axis;
  final String pWaveMorph;
  final String atrialEnlargement;
  final String hypertrophy;
  final String bbb;
  final String qWaves;
  final String ischemia;
  final String tWave;
  final bool triedSubmit;

  final ValueChanged<String> onAxisChanged;
  final ValueChanged<String> onPWaveMorphChanged;
  final ValueChanged<String> onAtrialEnlargementChanged;
  final ValueChanged<String> onHypertrophyChanged;
  final ValueChanged<String> onBbbChanged;
  final ValueChanged<String> onQWavesChanged;
  final ValueChanged<String> onIschemiaChanged;
  final ValueChanged<String> onTWaveChanged;
  final ValueChanged<String> onInteracted;

  const MorphologyPage({
    super.key,
    required this.axis,
    required this.pWaveMorph,
    required this.atrialEnlargement,
    required this.hypertrophy,
    required this.bbb,
    required this.qWaves,
    required this.ischemia,
    required this.tWave,
    required this.triedSubmit,
    required this.onAxisChanged,
    required this.onPWaveMorphChanged,
    required this.onAtrialEnlargementChanged,
    required this.onHypertrophyChanged,
    required this.onBbbChanged,
    required this.onQWavesChanged,
    required this.onIschemiaChanged,
    required this.onTWaveChanged,
    required this.onInteracted,
  });

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    final palette = CozyTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: palette.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
        Expanded(
          child: Divider(
            indent: 12,
            height: 24,
            color: palette.textSecondary.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    final palette = CozyTheme.of(context);
    bool hasError = triedSubmit && value.isEmpty;

    return InputDecorator(
      decoration: CozyTheme.inputDecoration(context, label).copyWith(
        labelStyle: TextStyle(color: hasError ? palette.error : null),
        enabledBorder: hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.error, width: 2),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          isExpanded: true,
          hint: Text(
            "Select $label...",
            style: TextStyle(
              fontSize: 14,
              color: hasError
                  ? palette.error.withValues(alpha: 0.5)
                  : palette.textSecondary,
            ),
          ),
          items: items
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(
                    r,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              onChanged(val);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader(context, "4. Axis", Icons.explore),
        const SizedBox(height: 16),
        _buildDropdown(context, "Heart Axis", axis, ECGWizardState.axisList,
            (v) {
          onAxisChanged(v);
          onInteracted("axis");
        }),
        const SizedBox(height: 32),
        _buildSectionHeader(context, "5/6/7. Morphology", Icons.graphic_eq),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                  context, "P-Wave", pWaveMorph, ECGWizardState.pMorphs, (v) {
                onPWaveMorphChanged(v);
                onInteracted("morphology");
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                context,
                "Atrial Enlargement",
                atrialEnlargement,
                ECGWizardState.atrialSizes,
                (v) {
                  onAtrialEnlargementChanged(v);
                  onInteracted("morphology");
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                context,
                "QRS Hypertrophy",
                hypertrophy,
                ECGWizardState.hypertrophyOpts,
                (v) {
                  onHypertrophyChanged(v);
                  onInteracted("morphology");
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                  context, "Bundle Branch Block", bbb, ECGWizardState.bbbOpts,
                  (v) {
                onBbbChanged(v);
                onInteracted("morphology");
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDropdown(
            context, "Pathological Q-Waves", qWaves, ECGWizardState.qWaveOpts,
            (v) {
          onQWavesChanged(v);
          onInteracted("morphology");
        }),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                  context, "ST Ischemia", ischemia, ECGWizardState.ischemiaOpts,
                  (v) {
                onIschemiaChanged(v);
                onInteracted("morphology");
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                  context, "T-Wave", tWave, ECGWizardState.tWaveOpts, (v) {
                onTWaveChanged(v);
                onInteracted("morphology");
              }),
            ),
          ],
        ),
      ],
    );
  }
}
