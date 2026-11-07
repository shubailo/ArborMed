import 'package:flutter/material.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../../features/ecg/providers/ecg_wizard_state.dart';
import 'ecg_section_header.dart';
import 'ecg_form_dropdown.dart';

class EcgMorphologyStep extends StatelessWidget {
  final String axis;
  final String pWaveMorph;
  final String atrialEnlargement;
  final String hypertrophy;
  final String bbb;
  final String qWaves;
  final String ischemia;
  final String tWave;
  final Set<String> autofilledFields;
  final ValueChanged<String> onAxisChanged;
  final ValueChanged<String> onPWaveMorphChanged;
  final ValueChanged<String> onAtrialEnlargementChanged;
  final ValueChanged<String> onHypertrophyChanged;
  final ValueChanged<String> onBbbChanged;
  final ValueChanged<String> onQWavesChanged;
  final ValueChanged<String> onIschemiaChanged;
  final ValueChanged<String> onTWaveChanged;

  const EcgMorphologyStep({
    super.key,
    required this.axis,
    required this.pWaveMorph,
    required this.atrialEnlargement,
    required this.hypertrophy,
    required this.bbb,
    required this.qWaves,
    required this.ischemia,
    required this.tWave,
    required this.autofilledFields,
    required this.onAxisChanged,
    required this.onPWaveMorphChanged,
    required this.onAtrialEnlargementChanged,
    required this.onHypertrophyChanged,
    required this.onBbbChanged,
    required this.onQWavesChanged,
    required this.onIschemiaChanged,
    required this.onTWaveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- STEP 4: AXIS ---
        EcgSectionHeader(title: l10n.adminEcgAxis, icon: Icons.explore),
        const SizedBox(height: 16),
        EcgFormDropdown(
          keyName: "axis",
          label: l10n.adminEcgHeartAxis,
          value: axis,
          items: ECGWizardState.axisList,
          icon: Icons.compass_calibration,
          isAutofilled: autofilledFields.contains("axis"),
          onChanged: onAxisChanged,
        ),
        const SizedBox(height: 24),

        // --- STEP 5: P-WAVE ---
        EcgSectionHeader(title: l10n.adminEcgPwaveMorph, icon: Icons.waves),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: EcgFormDropdown(
                keyName: "pwave.morph",
                label: l10n.adminEcgMorphology,
                value: pWaveMorph,
                items: ECGWizardState.pMorphs,
                icon: Icons.tune,
                isAutofilled: autofilledFields.contains("pwave.morph"),
                onChanged: onPWaveMorphChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: EcgFormDropdown(
                keyName: "pwave.enlargement",
                label: l10n.adminEcgAtrialEnlargement,
                value: atrialEnlargement,
                items: ECGWizardState.atrialSizes,
                icon: Icons.zoom_out_map,
                isAutofilled: autofilledFields.contains("pwave.enlargement"),
                onChanged: onAtrialEnlargementChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- STEP 6: QRS MORPHOLOGY ---
        EcgSectionHeader(title: l10n.adminEcgQrsMorph, icon: Icons.graphic_eq),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: EcgFormDropdown(
                keyName: "qrs.hypertrophy",
                label: l10n.adminEcgHypertrophy,
                value: hypertrophy,
                items: ECGWizardState.hypertrophyOpts,
                icon: Icons.line_weight,
                isAutofilled: autofilledFields.contains("qrs.hypertrophy"),
                onChanged: onHypertrophyChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: EcgFormDropdown(
                keyName: "qrs.bbb",
                label: l10n.adminEcgBbb,
                value: bbb,
                items: ECGWizardState.bbbOpts,
                icon: Icons.timeline,
                isAutofilled: autofilledFields.contains("qrs.bbb"),
                onChanged: onBbbChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        EcgFormDropdown(
          keyName: "qrs.qwaves",
          label: l10n.adminEcgPathQWaves,
          value: qWaves,
          items: ECGWizardState.qWaveOpts,
          icon: Icons.priority_high,
          isAutofilled: autofilledFields.contains("qrs.qwaves"),
          onChanged: onQWavesChanged,
        ),
        const SizedBox(height: 24),

        // --- STEP 7: ST-T MORPHOLOGY ---
        EcgSectionHeader(title: l10n.adminEcgStTMorph, icon: Icons.trending_up),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: EcgFormDropdown(
                keyName: "st.ischemia",
                label: l10n.adminEcgIschemia,
                value: ischemia,
                items: ECGWizardState.ischemiaOpts,
                icon: Icons.warning_amber,
                isAutofilled: autofilledFields.contains("st.ischemia"),
                onChanged: onIschemiaChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: EcgFormDropdown(
                keyName: "st.twave",
                label: l10n.adminEcgTWave,
                value: tWave,
                items: ECGWizardState.tWaveOpts,
                icon: Icons.waves,
                isAutofilled: autofilledFields.contains("st.twave"),
                onChanged: onTWaveChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

