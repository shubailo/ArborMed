import 'package:flutter/material.dart';
import '../../../../theme/cozy_theme.dart';

class EcgSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const EcgSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24, color: CozyTheme.of(context).primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 2, color: Colors.grey[100])),
      ],
    );
  }
}

