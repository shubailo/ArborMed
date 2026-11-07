import 'package:flutter/material.dart';
import '../../../../widgets/admin/dynamic_option_list.dart';

class SingleChoiceEditor extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final ValueChanged<List<String>> onOptionsChanged;
  final ValueChanged<int> onCorrectIndexChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const SingleChoiceEditor({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.onOptionsChanged,
    required this.onCorrectIndexChanged,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return DynamicOptionList(
      options: options,
      correctIndex: correctIndex,
      onOptionsChanged: onOptionsChanged,
      onCorrectIndexChanged: onCorrectIndexChanged,
      onAdd: onAdd,
      onRemove: onRemove,
    );
  }
}

