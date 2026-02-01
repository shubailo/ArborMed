import 'package:flutter/material.dart';
import 'cozy_hub_button.dart';
import 'start_session_hero.dart';
import '../../theme/cozy_theme.dart';

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
        const SnackBar(
          content: Text('Note already sent. Cooldown: 25h.'),
          backgroundColor: Color(0xFF8CAA8C),
          duration: Duration(seconds: 1),
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
                Image.asset('assets/ui/buttons/stethoscope_hud.png', width: 22, height: 22),
                "${widget.coins}",
              ),
              const SizedBox(width: 12),
              _buildStatusPill(
                const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF8A65), size: 20),
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
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Image.asset(
                  'assets/ui/buttons/heart.png',
                  fit: BoxFit.contain,
                  color: _hasLiked ? Colors.grey : null, // Dim if used
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

               CozyHubButton(
                 label: "Network",
                 assetName: "network",
                 fallbackIcon: Icons.people_rounded,
                 onTap: widget.onNetworkTap,
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
                 fallbackIcon: widget.isVisiting ? Icons.home_rounded : Icons.medical_services_rounded,
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
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
       decoration: BoxDecoration(
         color: CozyTheme.paperWhite.withValues(alpha: 0.95),
         borderRadius: BorderRadius.circular(20),
         boxShadow: CozyTheme.shadowSmall,
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           leading,
           const SizedBox(width: 8),
           Text(
             value,
             style: CozyTheme.textTheme.labelLarge?.copyWith(
               color: CozyTheme.textPrimary,
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
  const HeartBubble({required Key key, required this.onComplete}) : super(key: key);

  @override
  State<HeartBubble> createState() => _HeartBubbleState();
}

class _HeartBubbleState extends State<HeartBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));
    _yAnimation = Tween<double>(begin: 0, end: -250).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut)
    );
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
    return AnimatedBuilder(
      animation: _controller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF8CAA8C),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/ui/buttons/stethoscope_hud.png', width: 18, height: 18, color: Colors.white),
            const SizedBox(width: 6),
            const Text(
              "Consultation Sent +5 🩺",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
