import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class FloatingMedicalIcons extends StatefulWidget {
  final Color color;
  const FloatingMedicalIcons({super.key, required this.color});

  @override
  State<FloatingMedicalIcons> createState() => _FloatingMedicalIconsState();
}

class _FloatingMedicalIconsState extends State<FloatingMedicalIcons>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<FloatingItem> _items = [];
  Timer? _refreshTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _spawnInitialIcons();

    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cycleIcons();
    });
  }

  void _spawnInitialIcons() {
    for (int i = 0; i < 12; i++) {
      _items.add(_createRandomItem(entryTime: DateTime.now()));
    }
  }

  void _cycleIcons() {
    if (!mounted) return;
    setState(() {
      final now = DateTime.now();
      for (var item in _items) {
        item.exitTime = now;
      }
      for (int i = 0; i < 12; i++) {
        _items.add(_createRandomItem(entryTime: now));
      }
      _items.removeWhere((item) =>
          item.exitTime != null &&
          now.difference(item.exitTime!).inSeconds > 15);
    });
  }

  FloatingItem _createRandomItem({required DateTime entryTime}) {
    return FloatingItem(
      icon: _getRandomIcon(),
      startPosition: Offset(_random.nextDouble(), _random.nextDouble()),
      speed: 0.02 + _random.nextDouble() * 0.04,
      size: 20 + _random.nextDouble() * 30,
      angle: _random.nextDouble() * 2 * pi,
      entryTime: entryTime,
    );
  }

  IconData _getRandomIcon() {
    const icons = [
      Icons.local_hospital,
      Icons.favorite,
      Icons.medical_services,
      Icons.medication,
      Icons.healing,
      Icons.science,
      Icons.biotech,
      Icons.monitor_heart,
      Icons.thermostat,
    ];
    return icons[_random.nextInt(icons.length)];
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

    double opacity = 0.08;
    final now = DateTime.now();

    final timeAlive = now.difference(item.entryTime).inMilliseconds;
    if (timeAlive < 2000) {
      opacity *= (timeAlive / 2000);
    }

    if (item.exitTime != null) {
      final timeSinceExit = now.difference(item.exitTime!).inMilliseconds;
      opacity *= (1.0 - (timeSinceExit / 5000).clamp(0.0, 1.0));
    }

    return Align(
      alignment: Alignment(dx * 2 - 1, dy * 2 - 1),
      child: Transform.rotate(
        angle: progress * 2 * pi * 0.1,
        child: Opacity(
          opacity: opacity.clamp(0.0, 0.08),
          child: Icon(item.icon, size: item.size, color: widget.color),
        ),
      ),
    );
  }
}

class FloatingItem {
  final IconData icon;
  final Offset startPosition;
  final double speed;
  final double size;
  final double angle;
  final DateTime entryTime;
  DateTime? exitTime;

  FloatingItem({
    required this.icon,
    required this.startPosition,
    required this.speed,
    required this.size,
    required this.angle,
    required this.entryTime,
    this.exitTime,
  });
}
