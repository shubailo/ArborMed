import 'package:flutter/material.dart';
import 'platform_image_stub.dart'
    if (dart.library.io) 'platform_image_native.dart'
    if (dart.library.html) 'platform_image_web.dart'
    if (dart.library.js_interop) 'platform_image_web.dart';

class PlatformImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PlatformImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return getPlatformImage(
      path,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
