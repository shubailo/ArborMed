import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:student_app/core/theme/cozy_theme.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/ui/paper_texture.dart';
import 'package:student_app/core/ui/pressable_mixin.dart';

enum CozyPanelVariant { cream, white }

class CozyPanel extends StatefulWidget {
  final Widget child;
  final String? title;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final CozyPanelVariant variant;
  final bool hasTexture;
  final bool animateIn;
  final Color? backgroundColor;

  const CozyPanel({
    super.key,
    required this.child,
    this.title,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.variant = CozyPanelVariant.white,
    this.hasTexture = false,
    this.animateIn = false,
    this.backgroundColor,
  });

  @override
  State<CozyPanel> createState() => _CozyPanelState();
}

class _CozyPanelState extends State<CozyPanel>
    with SingleTickerProviderStateMixin, PressableMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    if (widget.animateIn) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CozyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateIn && !oldWidget.animateIn) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null;
    final bgColor = widget.backgroundColor ??
        (widget.variant == CozyPanelVariant.cream
            ? AppTheme.paperCream
            : AppTheme.paperWhite);

    final double radius = widget.borderRadius ??
        (widget.variant == CozyPanelVariant.cream ? 24 : 16);

    final shadowOffset = isInteractive ? getShadowOffset(pressed: 1, normal: 4) : 4.0;
    final shadowBlur = isInteractive ? getShadowBlur(pressed: 2, normal: 8) : 8.0;

    Widget panel = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: widget.padding ?? const EdgeInsets.all(CozyTheme.spacingLarge),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isInteractive && _isHovering
              ? AppTheme.sageGreen
              : AppTheme.warmBrown.withValues(alpha: 0.1),
          width: isInteractive && _isHovering ? 2.5 : 1.5,
        ),
        boxShadow: isInteractive && _isHovering
            ? [
                BoxShadow(
                  color: AppTheme.sageGreen.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: AppTheme.warmBrown.withValues(alpha: 0.05),
                  blurRadius: shadowBlur,
                  offset: Offset(0, shadowOffset),
                )
              ],
      ),
      child: widget.hasTexture
          ? PaperTexture(opacity: 0.03, child: widget.child)
          : widget.child,
    );

    if (isInteractive) {
      panel = MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: SystemMouseCursors.click,
        child: buildPressable(
          isEnabled: true,
          onTap: widget.onTap,
          scale: 0.98,
          child: panel,
        ),
      );
    }

    Widget content = SlideTransition(position: _offsetAnimation, child: panel);

    if (widget.title == null) return content;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        content,
        Positioned(
          top: -14,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.paperWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.sageGreen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warmBrown.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                widget.title!.toUpperCase(),
                style: GoogleFonts.figtree(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppTheme.warmBrown.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
