import 'package:flutter/material.dart';
import '../../../../theme/cozy_theme.dart';
import 'ecg_localization_helper.dart';

class EcgFormDropdown extends StatelessWidget {
  final String keyName;
  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final bool isAutofilled;
  final ValueChanged<String> onChanged;

  const EcgFormDropdown({
    super.key,
    required this.keyName,
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    this.isAutofilled = false,
    required this.onChanged,
  });

  InputDecoration _getDecoration(BuildContext context, String label) {
    if (isAutofilled) {
      return CozyTheme.inputDecoration(context, label).copyWith(
        floatingLabelStyle: const TextStyle(
          backgroundColor: Colors.white,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.green.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      );
    }
    return CozyTheme.inputDecoration(context, label).copyWith(
      floatingLabelStyle: TextStyle(
        backgroundColor: CozyTheme.of(context).paperWhite,
        color: CozyTheme.of(context).primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveValue = items.contains(value)
        ? value
        : (items.firstWhere(
            (it) => it.toLowerCase() == value.toLowerCase(),
            orElse: () => items.first,
          ));

    final dropdown = DropdownButtonFormField<String>(
      initialValue: effectiveValue,
      isExpanded: true,
      decoration: _getDecoration(context, label).copyWith(
        prefixIcon: Icon(icon, color: Colors.grey),
        errorStyle: const TextStyle(height: 0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
      items: items
          .map(
            (r) => DropdownMenuItem(
              value: r,
              child: Text(
                EcgLocalizationHelper.getLocalizedOption(context, r),
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );

    if (!isAutofilled) return dropdown;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        dropdown,
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
}

