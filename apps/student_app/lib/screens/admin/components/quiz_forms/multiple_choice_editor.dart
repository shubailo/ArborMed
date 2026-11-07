import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../generated/l10n/app_localizations.dart';

class MultipleChoiceEditor extends StatelessWidget {
  final List<String> options;
  final List<int> correctIndices;
  final void Function(int index, String value) onOptionChanged;
  final void Function(int index, bool isSelected) onToggleCorrect;
  final VoidCallback onAddOption;
  final void Function(int index) onRemoveOption;

  const MultipleChoiceEditor({
    super.key,
    required this.options,
    required this.correctIndices,
    required this.onOptionChanged,
    required this.onToggleCorrect,
    required this.onAddOption,
    required this.onRemoveOption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.adminOptionsSelectCorrect,
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(options.length, (index) {
          final optText = options[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Checkbox(
                  value: correctIndices.contains(index),
                  onChanged: (val) => onToggleCorrect(index, val == true),
                ),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: optText)
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: optText.length),
                      ),
                    onChanged: (val) => onOptionChanged(index, val),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.adminOptionIndex(index + 1),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: options.length <= 2 ? null : () => onRemoveOption(index),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: onAddOption,
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.adminAddOption),
        ),
      ],
    );
  }
}

