import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../generated/l10n/app_localizations.dart';

class MultipleChoiceEditor extends StatefulWidget {
  final List<LocalKey> rowKeys;
  final List<String> options;
  final Set<int> correctIndices;
  final void Function(int index, String value) onOptionChanged;
  final void Function(int index, bool isSelected) onToggleCorrect;
  final VoidCallback onAddOption;
  final void Function(int index) onRemoveOption;

  const MultipleChoiceEditor({
    super.key,
    required this.options,
    required this.rowKeys,
    required this.correctIndices,
    required this.onOptionChanged,
    required this.onToggleCorrect,
    required this.onAddOption,
    required this.onRemoveOption,
  }) : assert(rowKeys.length == options.length);

  @override
  State<MultipleChoiceEditor> createState() => _MultipleChoiceEditorState();
}

class _MultipleChoiceEditorState extends State<MultipleChoiceEditor>
    with AutomaticKeepAliveClientMixin {
  // Each language tab owns its own editing state, even while offscreen.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final labels = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labels.adminOptionsSelectCorrect,
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(widget.options.length, (index) {
          final label = labels.adminOptionIndex(index + 1);
          return Padding(
            key: widget.rowKeys[index],
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Checkbox(
                  semanticLabel: '${labels.correctAnswer} · $label',
                  value: widget.correctIndices.contains(index),
                  onChanged: (val) =>
                      widget.onToggleCorrect(index, val == true),
                ),
                Expanded(
                  child: _OptionField(
                    text: widget.options[index],
                    label: label,
                    onChanged: (value) => widget.onOptionChanged(index, value),
                  ),
                ),
                IconButton(
                  tooltip: labels.delete,
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red),
                  onPressed: widget.options.length <= 2
                      ? null
                      : () => widget.onRemoveOption(index),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: widget.onAddOption,
          icon: const Icon(Icons.add),
          label: Text(labels.adminAddOption),
        ),
      ],
    );
  }
}

class _OptionField extends StatefulWidget {
  const _OptionField(
      {required this.text, required this.label, required this.onChanged});
  final String text;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  State<_OptionField> createState() => _OptionFieldState();
}

class _OptionFieldState extends State<_OptionField> {
  late final _controller = TextEditingController(text: widget.text);

  @override
  void didUpdateWidget(_OptionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.text;
    if (_controller.text == text) return;
    // A translation can replace the value while a field is selected.
    final selection = _controller.selection;
    _controller.value = TextEditingValue(
      text: text,
      selection: selection.isValid
          ? selection.copyWith(
              baseOffset: selection.baseOffset.clamp(0, text.length),
              extentOffset: selection.extentOffset.clamp(0, text.length),
            )
          : selection,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      );
}
