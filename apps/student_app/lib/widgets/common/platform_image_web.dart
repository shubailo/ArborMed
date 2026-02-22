import 'package:flutter/material.dart';

Widget getPlatformImage(String path, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  return Image.network(
    path,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
  );
}
