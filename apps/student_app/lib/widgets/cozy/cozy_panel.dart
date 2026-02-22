import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cozy_theme.dart';
import 'paper_texture.dart';
import 'pressable_mixin.dart';

enum CozyPanelVariant {
  cream, // CozyCard style
  white, // CozyTile style
}

class CozyPanel extends StatefulWidget {
  final Widget child;
  final String? title;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final CozyPanelVariant variant;
  final bool hasTexture;
  final bool isListTile;
  final Color? hoverBorderColor;
  final Color? backgroundColor;
  final BorderSide? border;

  const CozyPanel({
    super.key,
    required this.child,
    this.title,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.variant = CozyPanelVariant.white,
    this.hasTexture = false,
    this.isListTile = false,
    this.hoverBorderColor,
    this.backgroundColor,
    this.border,
  });

  @override
  State<CozyPanel> createState() => _CozyPanelState();
}

class _CozyPanelState extends State<CozyPanel> with PressableMixin {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final isInteractive = widget.onTap != null;

    final bgColor = widget.backgroundColor ??
        (widget.variant == CozyPanelVariant.cream
            ? palette.paperCream
            : palette.paperWhite);

    final double radius = widget.borderRadius ??
        (widget.variant == CozyPanelVariant.cream ? 24 : 16);

    final edgePadding = widget.padding ??
        (widget.isListTile
            ? const EdgeInsets.symmetric(vertical: 16, horizontal: 20)
            : (widget.variant == CozyPanelVariant.cream
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 28)
                : const EdgeInsets.all(16)));

    // Interactive states from Mixin
    final shadowOffset = isInteractive ? getShadowOffset(pressed: 1, normal: 4) : 4.0;
    final shadowBlur = isInteractive ? getShadowBlur(pressed: 2, normal: 8) : 8.0;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: edgePadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.fromBorderSide(
          widget.border ??
              BorderSide(
                color: isInteractive && _isHovering
                    ? (widget.hoverBorderColor ?? palette.primary)
                    : palette.textSecondary.withValues(alpha: 0.1),
                width: isInteractive && _isHovering ? 2.5 : 1.5,
              ),
        ),
        boxShadow: isInteractive && _isHovering
            ? [
                BoxShadow(
                  color: (widget.hoverBorderColor ?? palette.primary)
                      .withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: palette.textPrimary.withValues(alpha: 0.05),
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
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: SystemMouseCursors.click,
        child: buildPressable(
          isEnabled: true,
          onTap: widget.onTap,
          scale: 0.98,
          child: content,
        ),
      );
    }

    if (widget.title == null) return content;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        content,
        Positioned(
          top: -16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              decoration: BoxDecoration(
                color: palette.paperWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.textPrimary.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                widget.title!.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: palette.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
