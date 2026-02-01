import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import './icon_picker_dialog.dart';

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

    Widget content = Column(
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
                  color: const Color(0xFF8CAA8C).withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Center(
              child: _buildIcon(checkUrl, scale),
            ),
          )
        : SizedBox(
            width: 140, 
            height: 140, 
            child: Center(child: _buildIcon(checkUrl, scale)),
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
          const SizedBox(height: 8),
          Text(
            "- $author",
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF8D6E63).withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
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

  Widget _buildIcon(String? effectiveUrl, double scale) {
    if (effectiveUrl != null) {
      final imageWidget = ClipOval(
        child: Image.network(
          '${ApiService.baseUrl}$effectiveUrl',
          width: 70 * scale,
          height: 70 * scale,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      );
      
      return Transform.scale(
        scale: scale,
        child: imageWidget,
      );
    }

    // Default Material Icon
    return Icon(
      IconPickerDialog.getIconData(iconName),
      size: 70,
      color: const Color(0xFF8CAA8C),
    );
  }
}
