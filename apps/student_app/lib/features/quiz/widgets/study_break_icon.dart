import 'package:flutter/material.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../widgets/admin/icon_picker_dialog.dart';
import 'quote_icon_image.dart';

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
    String? checkUrl;
    final url = customUrl;

    if (url != null && url.isNotEmpty && url != 'random_gallery') {
      checkUrl = url;
    } else if (iconName.startsWith('/') || iconName.startsWith('http')) {
      checkUrl = iconName;
    }

    final image = QuoteIconImage.parse(checkUrl);
    final showBackground = image?.showBackground ?? true;
    const double baseSize = 70.0;

    Widget mainIcon;
    if (image != null) {
      mainIcon = Image.network(
        image.uri.toString(),
        width: baseSize * image.scale,
        height: baseSize * image.scale,
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
            : IconPickerDialog.getIconData(iconName),
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
