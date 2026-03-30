import 'package:flutter/material.dart';

enum ArborButtonType { primary, outline, text }

class ArborButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ArborButtonType type;

  const ArborButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ArborButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ArborButtonType.outline:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(text),
        );
      case ArborButtonType.text:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(text),
        );
      case ArborButtonType.primary:
      default:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(text),
        );
    }
  }
}
