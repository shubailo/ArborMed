import 'package:flutter/material.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/ui/floating_medical_icons.dart';

class CozyModalScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBackgroundIcons;

  const CozyModalScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showBackgroundIcons = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 600.0 : screenWidth * 0.95;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (showBackgroundIcons)
          Positioned.fill(
            child: IgnorePointer(
              child: FloatingMedicalIcons(
                color: AppTheme.warmBrown.withValues(alpha: 0.05),
              ),
            ),
          ),
        Container(
          width: dialogWidth,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppTheme.paperCream,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.warmBrown.withValues(alpha: 0.8), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Legacy Clipboard Handle
              Container(
                width: 80,
                height: 10,
                margin: const EdgeInsets.only(top: 10, bottom: 5),
                decoration: BoxDecoration(
                  color: AppTheme.warmBrown.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppTheme.warmBrown,
                  ),
                ),
              ),
              Flexible(child: child),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
