import 'package:flutter/material.dart';

/// Owns the single animation that can update the room viewport.
class RoomCamera {
  final TransformationController transform;
  final AnimationController _controller;
  Matrix4Tween? _movement;
  Curve _curve = Curves.linear;

  RoomCamera(this.transform, TickerProvider vsync)
      : _controller = AnimationController(vsync: vsync) {
    _controller.addListener(_apply);
  }

  void _apply() {
    transform.value = _movement!.transform(_curve.transform(_controller.value));
  }

  void animateTo(Matrix4 target, Duration duration,
      {Curve curve = Curves.easeInOutCubic}) {
    _controller.stop();
    _movement =
        Matrix4Tween(begin: transform.value.clone(), end: target.clone());
    _curve = curve;
    _controller.duration = duration;
    _controller.forward(from: 0);
  }

  void stop() => _controller.stop();

  void dispose() => _controller.dispose();
}
