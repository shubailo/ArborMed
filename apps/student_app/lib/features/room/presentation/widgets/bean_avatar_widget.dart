import 'package:flutter/material.dart';
import 'package:student_app/core/theme/app_theme.dart';

enum BeanMood { happy, focused, idle, tired, proud, concerned }

class BeanConfig {
  final Color? skinColor;
  final String? body;
  final String? head;
  final String? accessory;

  const BeanConfig({
    this.skinColor,
    this.body,
    this.head,
    this.accessory,
  });
}

class BeanAvatarWidget extends StatefulWidget {
  final BeanMood mood;
  final double size;
  final BeanConfig config;

  const BeanAvatarWidget({
    super.key,
    this.mood = BeanMood.idle,
    this.size = 120,
    this.config = const BeanConfig(),
  });

  @override
  State<BeanAvatarWidget> createState() => _BeanAvatarWidgetState();
}

class _BeanAvatarWidgetState extends State<BeanAvatarWidget>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;

  late final AnimationController _tapController;
  late final Animation<double> _tapAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _tapAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathController, _tapController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _tapAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _breathAnimation.value),
              child: SizedBox(
                width: widget.size,
                height: widget.size * 1.2,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Layer 1: Base (Skin)
                    _buildBody(),
                    
                    // Layer 2: Clothing/Body Accessory
                    if (widget.config.body != null) _buildBodyLayer(widget.config.body!),

                    // Layer 3: Face (Mouth & Eyes)
                    _buildFace(),

                    // Layer 4: Head Accessory
                    if (widget.config.head != null) _buildHeadLayer(widget.config.head!),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      width: widget.size * 0.8,
      height: widget.size * 1.1,
      decoration: BoxDecoration(
        color: widget.config.skinColor ?? AppTheme.sageGreen,
        borderRadius: BorderRadius.all(
          Radius.elliptical(widget.size * 0.4, widget.size * 0.55),
        ),
        border: Border.all(color: AppTheme.warmBrown.withValues(alpha: 0.8), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmBrown.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
    );
  }

  Widget _buildFace() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Eyes
        Positioned(
          top: widget.size * 0.35,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEye(),
              SizedBox(width: widget.size * 0.18),
              _buildEye(),
            ],
          ),
        ),
        // Mouth
        Positioned(top: widget.size * 0.55, child: _buildMouth()),
      ],
    );
  }

  Widget _buildBodyLayer(String item) {
    return Positioned(
      bottom: widget.size * 0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.warmBrown.withValues(alpha: 0.2)),
        ),
        child: Text(item, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeadLayer(String item) {
    return Positioned(
      top: -10,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Icon(Icons.school, size: 24, color: AppTheme.softClay),
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: widget.size * 0.12,
      height: widget.size * 0.12,
      decoration: const BoxDecoration(
        color: AppTheme.warmBrown,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMouth() {
    switch (widget.mood) {
      case BeanMood.happy:
      case BeanMood.proud:
        return Container(
          width: widget.size * 0.2,
          height: widget.size * 0.1,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.warmBrown, width: 2.5),
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        );
      case BeanMood.focused:
        return Container(
          width: widget.size * 0.15,
          height: 3,
          decoration: BoxDecoration(
            color: AppTheme.warmBrown,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case BeanMood.concerned:
      case BeanMood.tired:
        return Container(
          width: widget.size * 0.1,
          height: widget.size * 0.05,
          decoration: BoxDecoration(
            color: AppTheme.warmBrown.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      case BeanMood.idle:
        return Container(
          width: widget.size * 0.08,
          height: 2,
          color: AppTheme.warmBrown,
        );
    }
  }
}
