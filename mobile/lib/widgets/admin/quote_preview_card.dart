import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/stats_provider.dart';
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
    bool showBackground = true;
    double scale = 1.0;
    
    // Check if we have a custom URL and parse params for container
    String? checkUrl;
    if (customIconUrl != null && customIconUrl!.isNotEmpty) {
      checkUrl = customIconUrl;
    } else if (iconName.startsWith('/') || iconName.startsWith('http')) {
      checkUrl = iconName;
    }

    if (checkUrl != null) {
       try {
        final uri = Uri.parse(checkUrl);
        if (uri.queryParameters.containsKey('bg')) {
          showBackground = uri.queryParameters['bg'] == 'true';
        }
        if (uri.queryParameters.containsKey('scale')) {
          scale = double.tryParse(uri.queryParameters['scale'] ?? '1.0') ?? 1.0;
        }
      } catch (_) {}
    }

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          showBackground 
          ? Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFF8CAA8C), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8CAA8C).withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Center(
                child: _buildIcon(context, checkUrl, scale, true),
              ),
            )
          : Container(
              constraints: const BoxConstraints(
                minWidth: 140,
                minHeight: 140,
                maxWidth: 200,
                maxHeight: 200,
              ),
              child: Center(child: _buildIcon(context, checkUrl, scale, false)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.quicksand(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text.isEmpty ? "Quote text will appear here..." : text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF8D6E63),
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
                  color: const Color(0xFF8D6E63).withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5E6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEDCC5)),
      ),
      child: content,
    );
  }

  Widget _buildIcon(BuildContext context, String? effectiveUrl, double scale, bool useClip) {
    const double baseSize = 110.0; // Increased from 70
    String? finalUrl = effectiveUrl;

    // Handle Random Gallery Mode
    if (effectiveUrl == 'random_gallery') {
      final stats = Provider.of<StatsProvider>(context, listen: false);
      if (stats.uploadedIcons.isNotEmpty) {
        // Use a simple random pick
        finalUrl = stats.uploadedIcons[Random().nextInt(stats.uploadedIcons.length)];
      } else {
        finalUrl = null; // Fallback to default icon
      }
    }

    if (finalUrl != null && finalUrl != 'random_gallery') {
      final imageWidget = Image.network(
        '${ApiService.baseUrl}$finalUrl',
        width: baseSize * scale,
        height: baseSize * scale,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
      
      return Transform.scale(
        scale: scale,
        child: useClip ? ClipOval(child: imageWidget) : imageWidget,
      );
    }

    // Default Material Icon
    return Icon(
      IconPickerDialog.getIconData(iconName),
      size: baseSize,
      color: const Color(0xFF8CAA8C),
    );
  }
}
