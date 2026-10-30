import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async'; // Added

class FloatingMedicalIcons extends StatefulWidget {
  final Color color;
  const FloatingMedicalIcons({super.key, required this.color});

  @override
  State<FloatingMedicalIcons> createState() => _FloatingMedicalIconsState();
}

class _FloatingMedicalIconsState extends State<FloatingMedicalIcons>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<FloatingItem> _items = []; // Active items
  Timer? _refreshTimer;
  final Random _random = Random();

  // 📝 User custom file names
  final List<String> _customAssetPaths = [
    'assets/icons/floating/Kép1.png',
    'assets/icons/floating/Kép2.png',
    'assets/icons/floating/Kép3.png',
    'assets/icons/floating/Kép4.png',
    'assets/icons/floating/Kép5.png',
    'assets/icons/floating/Kép6.png',
    'assets/icons/floating/Kép7.png',
    'assets/icons/floating/Kép8.png',
    'assets/icons/floating/Kép9.png',
    'assets/icons/floating/Kép10.png',
    'assets/icons/floating/Kép11.png',
    'assets/icons/floating/Kép12.png',
    'assets/icons/floating/Kép13.png',
    'assets/icons/floating/Kép14.png',
    'assets/icons/floating/Kép15.png',
    'assets/icons/floating/Kép16.png',
    'assets/icons/floating/Kép17.png',
    'assets/icons/floating/Kép18.png',
    'assets/icons/floating/Kép19.png',
    'assets/icons/floating/Kép20.png',
    'assets/icons/floating/Kép21.png',
    'assets/icons/floating/Kép22.png',
    'assets/icons/floating/Kép23.png',
    'assets/icons/floating/Kép24.png',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _spawnInitialIcons();

    // 🔄 Refresh every 10 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _cycleIcons();
    });
  }

  void _spawnInitialIcons() {
    // Spawn 15 items as requested
    for (int i = 0; i < 15; i++) {
      _items.add(_createRandomItem(entryTime: DateTime.now()));
    }
  }

  void _cycleIcons() {
    setState(() {
      // 1. Mark current items as exiting
      final now = DateTime.now();
      for (var item in _items) {
        item.exitTime = now;
      }

      // 2. Spawn 15 NEW items
      for (int i = 0; i < 15; i++) {
        _items.add(_createRandomItem(entryTime: now));
      }

      // 3. Cleanup very old items (older than 15 seconds after exit)
      _items.removeWhere((item) =>
          item.exitTime != null &&
          now.difference(item.exitTime!).inSeconds > 15);
    });
  }

  FloatingItem _createRandomItem({required DateTime entryTime}) {
    return FloatingItem(
      icon: _getRandomIcon(),
      assetPath: _getRandomAsset(),
      startPosition: Offset(_random.nextDouble(), _random.nextDouble()),
      speed: 0.02 + _random.nextDouble() * 0.04,
      size: 25 + _random.nextDouble() * 35,
      angle: _random.nextDouble() * 2 * pi,
      entryTime: entryTime,
    );
  }

  // ... [Keep _getRandomIcon and _getRandomAsset same as before] ...
  IconData? _getRandomIcon() {
    // If we have custom assets and valid roll, maybe return null to use asset?
    const icons = [
      Icons.local_hospital,
      Icons.medical_services,
      Icons.medication,
      Icons.healing,
      Icons.check_circle_outline,
      Icons.science,
      Icons.biotech,
      Icons.monitor_heart,
      Icons.thermostat,
    ];
    return icons[_random.nextInt(icons.length)];
  }

  String? _getRandomAsset() {
    if (_customAssetPaths.isEmpty) return null;
    if (_random.nextBool()) {
      return _customAssetPaths[_random.nextInt(_customAssetPaths.length)];
    }
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      // 🎨 ISOLATE BACKROUND FROM HUD
      child: LayoutBuilder(builder: (context, constraints) {
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: _items.map((item) {
                return _buildFloatingWidget(item, containerSize);
              }).toList(),
            );
          },
        );
      }),
    );
  }

  Widget _buildFloatingWidget(FloatingItem item, Size containerSize) {
    final double progress = _controller.value;
    final double dx =
        (item.startPosition.dx + (progress * item.speed * cos(item.angle))) %
            1.0;
    final double dy =
        (item.startPosition.dy + (progress * item.speed * sin(item.angle))) %
            1.0;

    // Handle Entry/Exit Opacity
    double opacity = 0.08; // Base opacity
    final now = DateTime.now();

    // Fade In
    final timeAlive = now.difference(item.entryTime).inMilliseconds;
    if (timeAlive < 2000) {
      opacity *= (timeAlive / 2000); // 0.0 to 1.0
    }

    // Fade Out
    if (item.exitTime != null) {
      final timeSinceExit = now.difference(item.exitTime!).inMilliseconds;
      opacity *=
          (1.0 - (timeSinceExit / 5000).clamp(0.0, 1.0)); // Fade out over 5s

      // "Float Outwards" simulation
      // We don't need complex re-calculation here, just subtle shift
    }

    return Align(
      alignment: Alignment(dx * 2 - 1, dy * 2 - 1),
      child: Transform.rotate(
        angle: progress * 2 * pi * 0.1,
        child: Opacity(
          opacity: opacity.clamp(0.0, 0.08),
          child: item.cachedWidget ??= _createItemWidget(item),
        ),
      ),
    );
  }

  Widget _createItemWidget(FloatingItem item) {
    if (item.assetPath != null) {
      return Image.asset(
        item.assetPath!,
        width: item.size,
        height: item.size,
        color: widget.color.withValues(alpha: 0.5), // Lower baseline opacity
        filterQuality: FilterQuality.low, // Performance win
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.broken_image_outlined,
              size: item.size, color: widget.color.withValues(alpha: 0.5));
        },
      );
    } else {
      return Icon(item.icon, size: item.size, color: widget.color);
    }
  }
}

class FloatingItem {
  final IconData? icon;
  final String? assetPath;
  final Offset startPosition;
  final double speed;
  final double size;
  final double angle;
  final DateTime entryTime;
  DateTime? exitTime;
  Widget? cachedWidget; // 📝 Added to prevent widget recreation

  FloatingItem({
    this.icon,
    this.assetPath,
    required this.startPosition,
    required this.speed,
    required this.size,
    required this.angle,
    required this.entryTime,
    this.exitTime,
  });
}
