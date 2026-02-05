import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cozy_theme.dart';

class DynamicOptionList extends StatefulWidget {
  final List<String> options;
  final int correctIndex;
  final ValueChanged<List<String>> onOptionsChanged;
  final ValueChanged<int> onCorrectIndexChanged;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onRemove;
  final bool isReadOnly;

  const DynamicOptionList({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.onOptionsChanged,
    required this.onCorrectIndexChanged,
    this.onAdd,
    this.onRemove,
    this.isReadOnly = false,
  });

  @override
  State<DynamicOptionList> createState() => _DynamicOptionListState();
}

class _DynamicOptionListState extends State<DynamicOptionList> {
  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _rebuildControllers();
  }

  @override
  void didUpdateWidget(covariant DynamicOptionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.length != widget.options.length || 
        oldWidget.options != widget.options) {
      // Rebuild if length changes or content changes externally
      // To preserve cursor, we ideally map provided options to existing controllers if count matches
      if (oldWidget.options.length == widget.options.length) {
         // ✅ Defer controller updates to avoid setState during build
         WidgetsBinding.instance.addPostFrameCallback((_) {
           for(int i=0; i<_controllers.length; i++) {
             if (_controllers[i].text != widget.options[i]) {
               _controllers[i].text = widget.options[i];
             }
           }
         });
      } else {
        _rebuildControllers();
      }
    }
  }

  void _rebuildControllers() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _controllers = widget.options.map((text) => TextEditingController(text: text)).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }



  void _addOption() {
    if (widget.onAdd != null) {
      widget.onAdd!();
    } else {
      final newOptions = List<String>.from(widget.options)..add("");
      widget.onOptionsChanged(newOptions);
    }
  }

  void _removeOption(int index) {
    if (widget.onRemove != null) {
      widget.onRemove!(index);
    } else {
      if (widget.options.length <= 2) return;
      final newOptions = List<String>.from(widget.options)..removeAt(index);
      widget.onOptionsChanged(newOptions);
      // Adjust correct index logic in parent or here?
      // If parent handles remove, parent handles index.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Answers & Options", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: CozyTheme.of(context).textPrimary)),
        const SizedBox(height: 12),
        ...List.generate(widget.options.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Radio<int>(
                  value: index, 
                  // ignore: deprecated_member_use
                  groupValue: widget.correctIndex,
                  activeColor: CozyTheme.of(context).primary,
                  // ignore: deprecated_member_use
                  onChanged: widget.isReadOnly ? null : (val) {
                    if (val != null) widget.onCorrectIndexChanged(val);
                  },
                ),
                Expanded(
                  child: TextFormField(
                    controller: _controllers[index],
                    decoration: CozyTheme.inputDecoration(context, "Option ${index + 1}"),
                    onChanged: (val) {
                      // Update logic without full rebuild if possible, but for now propagate up
                      // Actually, we must update the list in parent
                      final newOptions = List<String>.from(widget.options);
                      newOptions[index] = val;
                      widget.onOptionsChanged(newOptions);
                    },
                    readOnly: widget.isReadOnly,
                  ),
                ),
                if (!widget.isReadOnly && widget.options.length > 2)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: CozyTheme.of(context).error),
                    onPressed: () => _removeOption(index),
                  ),
              ],
            ),
          );
        }),
        if (!widget.isReadOnly && widget.options.length < 6)
          TextButton.icon(
            onPressed: _addOption,
            icon: const Icon(Icons.add),
            label: const Text("Add Option"),
          ),
      ],
    );
  }
}
