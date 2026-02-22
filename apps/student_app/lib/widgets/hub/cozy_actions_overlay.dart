import 'package:flutter/material.dart';
import 'cozy_hub_button.dart';
import 'start_session_hero.dart';
import '../../theme/cozy_theme.dart';
import '../../services/notification_provider.dart';
import 'package:provider/provider.dart';

class CozyActionsOverlay extends StatefulWidget {
  final int coins;
  final int streak;
  final bool isVisiting;
  final VoidCallback onProfileTap;
  final VoidCallback onNetworkTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onEquipTap;
  final VoidCallback onStartTap;
  final VoidCallback? onLikeTap;

  const CozyActionsOverlay({
    super.key,
    required this.coins,
    required this.streak,
    this.isVisiting = false,
    required this.onProfileTap,
    required this.onNetworkTap,
    required this.onSettingsTap,
    required this.onEquipTap,
    required this.onStartTap,
    this.onLikeTap,
  });

  @override
  State<CozyActionsOverlay> createState() => _CozyActionsOverlayState();
}

class _CozyActionsOverlayState extends State<CozyActionsOverlay> {
  final List<Widget> _bubbles = [];
  bool _hasLiked = false; // Simple local cooldown for MVP

  void _addHeartBubble() {
    if (_hasLiked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note already sent. Cooldown: 25h.'),
          backgroundColor: CozyTheme.of(context, listen: false).primary,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final key = UniqueKey();
    setState(() {
      _hasLiked = true;
      _bubbles.add(
        HeartBubble(
          key: key,
          onComplete: () {
            setState(() {
              _bubbles.removeWhere((w) => w.key == key);
            });
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // --- TOP LEFT HUD (Status Row) ---
        Positioned(
          top: 50, // Safe Area
          left: 20,
          child: Row(
            children: [
              _buildStatusPill(
                Image.asset('assets/ui/buttons/stethoscope_hud.png',
                    width: 22, height: 22),
                "${widget.coins}",
              ),
              const SizedBox(width: 12),
              _buildStatusPill(
                Icon(Icons.local_fire_department_rounded,
                    color: CozyTheme.of(context).warning, size: 20),
                "${widget.streak}",
              ),
            ],
          ),
        ),

        // --- VISITING INTERACTION ---
        if (widget.isVisiting)
          Positioned(
            top: 105,
            right: 20,
            child: GestureDetector(
              onTap: () {
                _addHeartBubble();
                widget.onLikeTap?.call();
              },
              child: Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      CozyTheme.of(context).paperWhite.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: CozyTheme.of(context)
                            .textPrimary
                            .withValues(alpha: 0.12),
                        blurRadius: 4)
                  ],
                ),
                child: Image.asset(
                  'assets/ui/buttons/heart.png',
                  fit: BoxFit.contain,
                  color: _hasLiked
                      ? CozyTheme.of(context)
                          .textSecondary
                          .withValues(alpha: 0.5)
                      : null, // Dim if used
                ),
              ),
            ),
          ),

        // Floating bubbles go here
        ..._bubbles,

        // --- BOTTOM LEFT ACTIONS ---
        Positioned(
          bottom: 30,
          left: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<NotificationProvider>(
                builder: (context, pager, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CozyHubButton(
                      label: "Network",
                      assetName: "network",
                      fallbackIcon: Icons.people_rounded,
                      onTap: widget.onNetworkTap,
                    ),
                    if (pager.unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: CozyTheme.of(context).error,
                              shape: BoxShape.circle),
                          child: Text(
                            "${pager.unreadCount}",
                            style: TextStyle(
                                color: CozyTheme.of(context).textInverse,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CozyHubButton(
                label: "Profile",
                assetName: "profile",
                fallbackIcon: Icons.person_rounded,
                onTap: widget.onProfileTap,
              ),
            ],
          ),
        ),

        // --- BOTTOM RIGHT ACTIONS ---
        Positioned(
          bottom: 30,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CozyHubButton(
                label: widget.isVisiting ? "Home" : "Equip",
                assetName: widget.isVisiting ? "home" : "equip",
                fallbackIcon: widget.isVisiting
                    ? Icons.home_rounded
                    : Icons.medical_services_rounded,
                onTap: widget.onEquipTap,
              ),
              const SizedBox(height: 16),
              CozyHubButton(
                label: "Settings",
                assetName: "settings",
                fallbackIcon: Icons.settings_rounded,
                onTap: widget.onSettingsTap,
              ),
            ],
          ),
        ),

        // --- CENTER HERO ---
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: StartSessionHero(
              onTap: widget.onStartTap,
              label: widget.isVisiting ? "ADD NOTE" : "START SESSION",
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(Widget leading, String value) {
    final palette = CozyTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.paperWhite.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: palette.shadowSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.textPrimary,
                  fontSize: 16,
                ),
          ),
        ],
      ),
    );
  }
}

class HeartBubble extends StatefulWidget {
  final VoidCallback onComplete;
  const HeartBubble({required Key key, required this.onComplete})
      : super(key: key);

  @override
  State<HeartBubble> createState() => _HeartBubbleState();
}

class _HeartBubbleState extends State<HeartBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500));
    _yAnimation = Tween<double>(begin: 0, end: -250)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: palette.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: palette.shadowSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/ui/buttons/stethoscope_hud.png',
                width: 18, height: 18, color: palette.textInverse),
            const SizedBox(width: 6),
            Text(
              "Consultation Sent +5 🩺",
              style: TextStyle(
                  color: palette.textInverse,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ],
        ),
      ),
      builder: (context, child) {
        return Positioned(
          top: 105 + _yAnimation.value,
          left: 0,
          right: 0,
          child: Center(
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
