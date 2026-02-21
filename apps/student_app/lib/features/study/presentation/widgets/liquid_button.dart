import 'package:flutter/material.dart';
import 'package:student_app/core/theme/app_theme.dart';
import 'package:student_app/core/theme/cozy_theme.dart';

class LiquidButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const LiquidButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  State<LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<LiquidButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.onTap == null
                ? Colors.grey.shade300
                : AppTheme.sageGreen,
            borderRadius: CozyTheme.borderLarge,
            boxShadow: widget.onTap == null ? null : CozyTheme.cardShadow,
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Figtree',
                  ),
                ),
        ),
      ),
    );
  }
}
