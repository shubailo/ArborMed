import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';

class ECGInterpretationStep extends StatefulWidget {
  final Map<String, dynamic> userFindings;
  final Function(String, dynamic) onUpdate;

  const ECGInterpretationStep({
    super.key,
    required this.userFindings,
    required this.onUpdate,
  });

  @override
  State<ECGInterpretationStep> createState() => _ECGInterpretationStepState();
}

class _ECGInterpretationStepState extends State<ECGInterpretationStep> {
  final List<String> rhythmOpts = [
    'Regular',
    'Irregular',
    'Irregularly Irregular',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(palette, 'RHYTHM & RATE'),
          const SizedBox(height: 24),

          _buildLabel(palette, 'What is the rhythm regularity?'),
          const SizedBox(height: 12),
          _buildOptions(
            palette,
            rhythmOpts,
            widget.userFindings['rhythm'] ?? '',
            (val) => widget.onUpdate('rhythm', val),
          ),

          const SizedBox(height: 32),
          
          _buildLabel(palette, 'Is it a Sinus Rhythm?'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildChoiceChip(
                palette,
                'YES',
                widget.userFindings['is_sinus'] == true,
                () => widget.onUpdate('is_sinus', true),
              ),
              const SizedBox(width: 12),
              _buildChoiceChip(
                palette,
                'NO',
                widget.userFindings['is_sinus'] == false,
                () => widget.onUpdate('is_sinus', false),
              ),
            ],
          ),

          const SizedBox(height: 32),

          _buildLabel(palette, 'What is the ventricular rate (BPM)?'),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter value',
              suffixText: 'BPM',
              filled: true,
              fillColor: palette.paperWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.textSecondary.withValues(alpha: 0.1)),
              ),
            ),
            onChanged: (val) => widget.onUpdate('rate', int.tryParse(val) ?? 0),
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

  Widget _buildLabel(CozyPalette palette, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: palette.textSecondary,
      ),
    );
  }

  Widget _buildOptions(
    CozyPalette palette,
    List<String> options,
    String selected,
    Function(String) onSelect,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((opt) {
        return _buildChoiceChip(
          palette,
          opt,
          selected == opt,
          () => onSelect(opt),
        );
      }).toList(),
    );
  }

  Widget _buildChoiceChip(
    CozyPalette palette,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary : palette.paperWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? palette.primary : palette.textSecondary.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : palette.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
