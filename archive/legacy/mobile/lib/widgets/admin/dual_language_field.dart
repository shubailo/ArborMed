import 'package:flutter/material.dart';
import '../../theme/cozy_theme.dart';

class DualLanguageField extends StatelessWidget {
  final TextEditingController controllerEn;
  final TextEditingController controllerHu;
  final String label;
  final String currentLanguage; // 'en' or 'hu'
  final bool isMultiLine;
  final VoidCallback? onTranslate;
  final bool isTranslating;
  final String? Function(String?)? validator;
  final Widget? trailingAction;
  final Function(String)? onChanged;

  const DualLanguageField({
    super.key,
    required this.controllerEn,
    required this.controllerHu,
    required this.label,
    required this.currentLanguage,
    this.isMultiLine = false,
    this.onTranslate,
    this.isTranslating = false,
    this.validator,
    this.trailingAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = currentLanguage == 'en' ? controllerEn : controllerHu;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trailingAction != null) ...[
          Align(alignment: Alignment.centerRight, child: trailingAction!),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: TextFormField(
            controller: controller,
            maxLines: isMultiLine ? 3 : 1,
            onChanged: onChanged,
            validator: validator ??
                (val) {
                  if (val == null || val.trim().isEmpty) {
                    return '$label (${currentLanguage.toUpperCase()}) is required';
                  }
                  return null;
                },
            decoration: CozyTheme.inputDecoration(
                    context, "$label (${currentLanguage.toUpperCase()})")
                .copyWith(
              alignLabelWithHint: isMultiLine,
              suffixIcon: onTranslate != null
                  ? IconButton(
                      icon: isTranslating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.translate),
                      onPressed: isTranslating ? null : onTranslate,
                      tooltip:
                          "Translate from ${currentLanguage == 'en' ? 'HU' : 'EN'}",
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
