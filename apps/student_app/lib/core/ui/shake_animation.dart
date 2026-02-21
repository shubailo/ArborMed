import 'package:flutter/material.dart';

class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool shake;
  final double shakeOffset;
  final Duration duration;

  const ShakeAnimation({
    super.key,
    required this.child,
    this.shake = false,
    this.shakeOffset = 6.0,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1, end: -1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -1, end: 1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1, end: -1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -1, end: 0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value * widget.shakeOffset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
