import 'package:flutter/material.dart';
import '../../theme/cozy_theme.dart';

class CozyTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isListTile;
  final Color? hoverBorderColor;
  final Color? backgroundColor;
  final BorderSide? border;
  final EdgeInsets? padding;

  const CozyTile({
    super.key, 
    required this.child, 
    required this.onTap, 
    this.isListTile = false,
    this.hoverBorderColor,
    this.backgroundColor,
    this.border,
    this.padding,
  });

  @override
  createState() => _CozyTileState();
}

class _CozyTileState extends State<CozyTile> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : (_isHovering ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: widget.padding ?? (widget.isListTile ? const EdgeInsets.symmetric(vertical: 16, horizontal: 20) : null),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? CozyTheme.of(context).paperWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.fromBorderSide(_isHovering 
                ? BorderSide(
                    color: (widget.hoverBorderColor ?? CozyTheme.of(context).primary), 
                    width: 2.5
                  )
                : (widget.border ?? BorderSide(color: CozyTheme.of(context).textSecondary.withValues(alpha: 0.2), width: 1.5))
              ),
              boxShadow: _isHovering 
                ? [BoxShadow(color: (widget.hoverBorderColor ?? CozyTheme.of(context).primary).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))] 
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))]
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
