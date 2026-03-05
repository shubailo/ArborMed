import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/avatar_config.dart';
import 'avatar_svg_builder.dart';

/// Renders a composited SVG avatar from an [AvatarConfig].
///
/// Uses [AvatarSvgBuilder] to generate the full SVG string,
/// then renders it via [SvgPicture.string].
class AvatarRenderer extends StatelessWidget {
  final AvatarConfig config;
  final double size;
  final Color? backgroundColor;
  final bool showBorder;

  const AvatarRenderer({
    super.key,
    required this.config,
    this.size = 120,
    this.backgroundColor,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final svgString = AvatarSvgBuilder.build(config);

    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.grey.shade100,
          border: showBorder
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                )
              : null,
          boxShadow: showBorder
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: SvgPicture.string(
          svgString,
          fit: BoxFit.contain,
          width: size,
          height: size,
        ),
      ),
    );
  }
}
