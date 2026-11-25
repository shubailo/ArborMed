import 'package:flutter/material.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../../features/ecg/providers/ecg_wizard_state.dart';
import 'ecg_section_header.dart';
import 'ecg_form_dropdown.dart';

class EcgRhythmConductionStep extends StatelessWidget {
  final String rhythmRegularity;
  final String conductionRatio;
  final bool isSinus;
  final TextEditingController rateController;
  final FormFieldValidator<String> validateRate;
  final String prCategory;
  final String qrsCategory;
  final String qtCategory;
  final String avBlock;
  final String saBlock;
  final String bbb;
  final Set<String> autofilledFields;
  final ValueChanged<String> onRegularityChanged;
  final ValueChanged<String> onConductionRatioChanged;
  final ValueChanged<bool> onSinusChanged;
  final ValueChanged<String> onRateChanged;
  final ValueChanged<String> onPrCategoryChanged;
  final ValueChanged<String> onQrsCategoryChanged;
  final ValueChanged<String> onQtCategoryChanged;
  final ValueChanged<String> onAvBlockChanged;
  final ValueChanged<String> onSaBlockChanged;
  final ValueChanged<String> onBbbChanged;
  final InputDecoration Function(String key, String label) getDecoration;

  const EcgRhythmConductionStep({
    super.key,
    required this.rhythmRegularity,
    required this.conductionRatio,
    required this.isSinus,
    required this.rateController,
    required this.validateRate,
    required this.prCategory,
    required this.qrsCategory,
    required this.qtCategory,
    required this.avBlock,
    required this.saBlock,
    required this.bbb,
    required this.autofilledFields,
    required this.onRegularityChanged,
    required this.onConductionRatioChanged,
    required this.onSinusChanged,
    required this.onRateChanged,
    required this.onPrCategoryChanged,
    required this.onQrsCategoryChanged,
    required this.onQtCategoryChanged,
    required this.onAvBlockChanged,
    required this.onSaBlockChanged,
    required this.onBbbChanged,
    required this.getDecoration,
  });

  Widget _autofillWrapper(String key, Widget child) {
    if (!autofilledFields.contains(key)) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -8,
          right: 12,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: const Icon(Icons.auto_awesome, size: 14, color: Colors.green),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- STEP 1: RHYTHM ---
        EcgSectionHeader(title: l10n.adminEcgRhythm, icon: Icons.show_chart),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: EcgFormDropdown(
                keyName: "rhythm.regularity",
                label: l10n.adminEcgRegularity,
                value: rhythmRegularity,
                items: ECGWizardState.regularityOpts,
                icon: Icons.linear_scale,
                isAutofilled: autofilledFields.contains("rhythm.regularity"),
                onChanged: onRegularityChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: EcgFormDropdown(
                keyName: "rhythm.ratio",
                label: l10n.adminEcgRatio,
                value: conductionRatio,
                items: ECGWizardState.conductionOpts,
                icon: Icons.compare_arrows,
                isAutofilled: autofilledFields.contains("rhythm.ratio"),
                onChanged: onConductionRatioChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: _autofillWrapper(
                "rhythm.sinus",
                InputDecorator(
                  decoration: getDecoration("rhythm.sinus", l10n.adminEcgSinusRhythm).copyWith(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  ),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 0.9,
                        child: Checkbox(
                          value: isSinus,
                          onChanged: (v) {
                            if (v != null) onSinusChanged(v);
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.adminEcgSinusHint,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- STEP 2: RATE ---
        EcgSectionHeader(title: l10n.adminEcgHeartRate, icon: Icons.timer),
        const SizedBox(height: 16),
        _autofillWrapper(
          "rate.max",
          TextFormField(
            controller: rateController,
            keyboardType: TextInputType.number,
            decoration: getDecoration("rate.max", l10n.adminEcgBpm).copyWith(
              prefixIcon: const Icon(Icons.favorite),
              helperText: l10n.adminEcgRateHint,
            ),
            validator: validateRate,
            onChanged: onRateChanged,
          ),
        ),
        const SizedBox(height: 24),

        // --- STEP 3: CONDUCTION ---
        EcgSectionHeader(title: l10n.adminEcgConduction, icon: Icons.speed),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: EcgFormDropdown(
                keyName: "conduction.pr",
                label: l10n.adminEcgPrInterval,
                value: prCategory,
                items: ECGWizardState.intervalOpts,
                icon: Icons.timer_outlined,
                isAutofilled: autofilledFields.contains("conduction.pr"),
                onChanged: onPrCategoryChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: EcgFormDropdown(
                keyName: "conduction.qrs",
                label: l10n.adminEcgQrsWidth,
                value: qrsCategory,
                items: ECGWizardState.intervalOpts,
                icon: Icons.width_normal,
                isAutofilled: autofilledFields.contains("conduction.qrs"),
                onChanged: onQrsCategoryChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: EcgFormDropdown(
                keyName: "conduction.qt",
                label: l10n.adminEcgQtInterval,
                value: qtCategory,
                items: ECGWizardState.intervalOpts,
                icon: Icons.av_timer,
                isAutofilled: autofilledFields.contains("conduction.qt"),
                onChanged: onQtCategoryChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Conditional Blocks
        if (prCategory == 'Prolonged') ...[
          EcgFormDropdown(
            keyName: "conduction.block",
            label: l10n.adminEcgAvBlock,
            value: avBlock,
            items: ECGWizardState.avBlocks,
            icon: Icons.block,
            isAutofilled: autofilledFields.contains("conduction.block"),
            onChanged: onAvBlockChanged,
          ),
          const SizedBox(height: 16),
        ],

        if (qrsCategory == 'Prolonged') ...[
          EcgFormDropdown(
            keyName: "qrs.bbb",
            label: l10n.adminEcgBbb,
            value: bbb,
            items: ECGWizardState.bbbOpts,
            icon: Icons.timeline,
            isAutofilled: autofilledFields.contains("qrs.bbb"),
            onChanged: onBbbChanged,
          ),
          const SizedBox(height: 16),
        ],

        EcgFormDropdown(
          keyName: "rhythm.sa_block",
          label: l10n.adminEcgSaBlock,
          value: saBlock,
          items: ECGWizardState.saBlocks,
          icon: Icons.timer_off,
          isAutofilled: autofilledFields.contains("rhythm.sa_block"),
          onChanged: onSaBlockChanged,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

