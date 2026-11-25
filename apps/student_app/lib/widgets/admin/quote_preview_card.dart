import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cozy_theme.dart';
import '../../features/quiz/widgets/quote_icon_image.dart';
import '../../services/admin_content_provider.dart';
import './icon_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class QuotePreviewCard extends StatelessWidget {
  final String text;
  final String author;
  final String title;
  final String iconName;
  final String? customIconUrl;

  const QuotePreviewCard({
    super.key,
    required this.text,
    required this.author,
    required this.title,
    this.iconName = 'menu_book_rounded',
    this.customIconUrl,
  });

  @override
  Widget build(BuildContext context) {
    String? checkUrl;
    if (customIconUrl != null && customIconUrl!.isNotEmpty) {
      checkUrl = customIconUrl;
    } else if (iconName == 'random_gallery' || iconName.startsWith('/') || iconName.startsWith('http')) {
      checkUrl = iconName;
    }

    if (checkUrl == 'random_gallery') {
      final icons = context.watch<AdminContentProvider>().uploadedIcons;
      checkUrl = icons.isEmpty ? null : icons[Random().nextInt(icons.length)];
    }
    final image = QuoteIconImage.parse(checkUrl);
    final showBackground = image?.showBackground ?? true;

    final palette = CozyTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.paperCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.textSecondary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            showBackground
                ? Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.paperWhite,
                      border: Border.all(color: palette.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: palette.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Center(
                      child: _buildIcon(context, image, true),
                    ),
                  )
                : Container(
                    constraints: const BoxConstraints(
                      minWidth: 140,
                      minHeight: 140,
                      maxWidth: 200,
                      maxHeight: 200,
                    ),
                    child: Center(
                        child: _buildIcon(context, image, false)),
                  ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.quicksand(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              text.isEmpty ? "Quote text will appear here..." : text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: palette.textSecondary,
                height: 1.3,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (author.isNotEmpty) ...[
              const SizedBox(height: 4), // Reduced from 8
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "- $author",
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textSecondary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(
      BuildContext context, QuoteIconImage? image, bool useClip) {
    const double baseSize = 110.0; // Increased from 70
    if (image != null) {
      final imageWidget = Image.network(
        image.uri.toString(),
        width: baseSize * image.scale,
        height: baseSize * image.scale,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image,
            size: 40,
            color: CozyTheme.of(context).textSecondary.withValues(alpha: 0.5)),
      );

      return Transform.scale(
        scale: image.scale,
        child: useClip ? ClipOval(child: imageWidget) : imageWidget,
      );
    }

    // Default Material Icon
    return Icon(
      IconPickerDialog.getIconData(iconName),
      size: baseSize,
      color: CozyTheme.of(context).primary,
    );
  }
}

