import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../services/admin_content_provider.dart';
import '../../../../services/api_service.dart';

class StudyBreakIcon extends StatelessWidget {
  final String iconName;
  final String? customUrl;

  const StudyBreakIcon({
    super.key,
    required this.iconName,
    this.customUrl,
  });

  @override
  Widget build(BuildContext context) {
    bool showBackground = true;
    double scale = 1.0;
    String? checkUrl;
    final url = customUrl;

    if (url == 'random_gallery' || iconName == 'random_gallery') {
      final contentProvider = Provider.of<AdminContentProvider>(context, listen: false);
      if (contentProvider.uploadedIcons.isNotEmpty) {
        checkUrl = contentProvider.uploadedIcons[
            Random().nextInt(contentProvider.uploadedIcons.length)];
      } else {
        checkUrl = null;
      }
    } else if (url != null && url.isNotEmpty) {
      checkUrl = url;
    } else if (iconName.startsWith('/') || iconName.startsWith('http')) {
      checkUrl = iconName;
    }

    if (checkUrl != null && checkUrl != 'random_gallery') {
      try {
        final uri = Uri.parse(checkUrl);
        if (uri.queryParameters.containsKey('bg')) {
          showBackground = uri.queryParameters['bg'] == 'true';
        }
        if (uri.queryParameters.containsKey('scale')) {
          scale = double.tryParse(uri.queryParameters['scale'] ?? '1.0') ?? 1.0;
        }
      } catch (e) {
        debugPrint('Error parsing checkUrl: $e');
      }
    }

    const double baseSize = 70.0;

    Widget mainIcon;
    if (checkUrl != null) {
      mainIcon = Image.network(
        '${ApiService.baseUrl}$checkUrl',
        width: baseSize * scale,
        height: baseSize * scale,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
      if (showBackground) {
        mainIcon = ClipOval(child: mainIcon);
      }
    } else {
      mainIcon = Icon(
        iconName == 'favorite_rounded'
            ? Icons.favorite_rounded
            : Icons.menu_book_rounded,
        size: 50,
        color: CozyTheme.of(context).primary,
      );
    }

    if (showBackground) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: mainIcon,
      );
    } else {
      return SizedBox(width: 90, height: 90, child: Center(child: mainIcon));
    }
  }
}
