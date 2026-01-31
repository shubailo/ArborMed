import 'package:flutter/material.dart';

class DualLanguageField extends StatelessWidget {
  final TextEditingController controllerEn;
  final TextEditingController controllerHu;
  final String label;
  final String currentLanguage; // 'en' or 'hu'
  final bool isMultiLine;
  final VoidCallback? onTranslate;
  final bool isTranslating;
  final String? Function(String?)? validator;

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
  });

  @override
  Widget build(BuildContext context) {
    final controller = currentLanguage == 'en' ? controllerEn : controllerHu;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Field Label with language indicator
            Row(
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: currentLanguage == 'en' ? Colors.blue[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: currentLanguage == 'en' ? Colors.blue[200]! : Colors.green[200]!,
                    ),
                  ),
                  child: Text(
                    currentLanguage.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: currentLanguage == 'en' ? Colors.blue[800] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            
            // Auto-translate button (only shown if onTranslate provided)
            if (onTranslate != null)
              TextButton.icon(
                onPressed: isTranslating ? null : onTranslate,
                icon: isTranslating 
                  ? const SizedBox(
                      width: 12, height: 12, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Icon(Icons.translate, size: 16),
                label: Text(
                  isTranslating ? "Translating..." : "Translate from ${currentLanguage == 'en' ? 'HU' : 'EN'}",
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: isMultiLine ? 3 : 1,
          validator: validator ?? (val) {
            if (val == null || val.trim().isEmpty) {
              return '$label (${currentLanguage.toUpperCase()}) is required';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: currentLanguage == 'en' 
              ? "Enter $label in English..." 
              : "Ide írd be: $label (magyarul)...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
