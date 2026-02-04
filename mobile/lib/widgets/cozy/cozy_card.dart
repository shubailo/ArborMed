import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cozy_theme.dart';
import 'paper_texture.dart';

class CozyCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;

  const CozyCard({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: CozyTheme.paperCream,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: CozyTheme.textPrimary.withValues(alpha: 0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: CozyTheme.textPrimary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: PaperTexture(
            opacity: 0.03,
            child: child,
          ),
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
                  border: Border.all(color: CozyTheme.textSecondary.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 2))
                  ]
                ),
                child: Text(
                  title!.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
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
