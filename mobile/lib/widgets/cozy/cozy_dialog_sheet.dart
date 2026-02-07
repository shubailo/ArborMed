import 'package:flutter/material.dart';
import '../../theme/cozy_theme.dart';
import 'floating_medical_icons.dart';

/// A standardized floating sheet/dialog used throughout the app.
/// Enforces consistent width (600), max height (600), and styling (Cozy Theme).
class CozyDialogSheet extends StatefulWidget {
  final Widget child;
  final VoidCallback onTapOutside;
  final String? title; // Optional header functionality if needed internally

  const CozyDialogSheet({
    super.key,
    required this.child,
    required this.onTapOutside,
    this.title,
  });

  @override
  createState() => _CozyDialogSheetState();
}

class _CozyDialogSheetState extends State<CozyDialogSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Quick pop-in animation
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  void _handleClose() {
    _controller.reverse().then((_) => widget.onTapOutside());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine Width: Fixed 600 on desktop/tablet, or 95% on mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = screenWidth > 600 ? 600.0 : screenWidth * 0.95;
    final dialogMaxHeight = screenHeight * 0.85;
    final palette = CozyTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Dimmed Background with Floating Icons
          Positioned.fill(
            child: GestureDetector(
              onTap: _handleClose, // Tap outside to close
              child: Container(
                color: Colors.black.withValues(alpha: 0.4), // Dim
                child: FloatingMedicalIcons(
                   color: palette.textInverse.withValues(alpha: 0.15), // Subtle icons on dim bg
                ),
              ),
            ),
          ),

          // 2. The Cozy Menu Card
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(maxHeight: dialogMaxHeight), // Enforce Standard Height Cap responsive
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: palette.paperCream,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: palette.textSecondary, width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        // Clipboard Top Handle Clip (Visual only)
                        Container(
                          width: 100,
                          height: 12,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: palette.textSecondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        
                        // Content
                        Flexible(child: widget.child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
