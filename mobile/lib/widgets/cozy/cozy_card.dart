import 'package:flutter/material.dart';
import '../../theme/cozy_theme.dart';

class CozyCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;

  const CozyCard({
    Key? key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(32),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: CozyTheme.textSecondary.withOpacity(0.2), width: 1),
            boxShadow: CozyTheme.shadowMedium,
          ),
          child: child,
        ),
        if (title != null)
          Positioned(
            top: -16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // Light amber/cream
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CozyTheme.textSecondary.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 2))
                  ]
                ),
                child: Text(
                  title!.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: CozyTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
