import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../theme/cozy_theme.dart';

/// Interactive ECG image viewer supporting pinch-to-zoom, pan, and full-screen view.
class EcgImageViewer extends StatelessWidget {
  final String imageUrl;
  final double? maxHeight;
  final bool isFullScreen;

  const EcgImageViewer({
    super.key,
    required this.imageUrl,
    this.maxHeight,
    this.isFullScreen = false,
  });

  String get _resolvedUrl {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    return '${ApiService.baseUrl}$imageUrl';
  }

  void _openFullScreen(BuildContext context) {
    final palette = CozyTheme.of(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => Scaffold(
        backgroundColor: palette.textPrimary.withValues(alpha: 0.92),
        body: Stack(
          children: [
            Center(
              child: EcgImageViewer(
                imageUrl: imageUrl,
                isFullScreen: true,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: palette.textInverse, size: 30),
                tooltip: 'Close full screen',
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    if (isFullScreen) {
      return Tooltip(
        message: 'Pan and zoom ECG',
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 6.0,
          child: Image.network(
            _resolvedUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (ctx, err, stack) => _buildErrorState(palette),
          ),
        ),
      );
    }

    final containerHeight = maxHeight ?? (MediaQuery.of(context).size.height * 0.45);

    return Stack(
      children: [
        Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: containerHeight),
          padding: const EdgeInsets.symmetric(horizontal: 48),
          color: palette.paperWhite,
          child: Tooltip(
            message: 'Tap to view full screen',
            child: GestureDetector(
              onTap: () => _openFullScreen(context),
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 6.0,
                child: Image.network(
                  _resolvedUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(color: palette.primary),
                      ),
                    );
                  },
                  errorBuilder: (ctx, err, stack) => _buildErrorState(palette),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: Icon(Icons.fullscreen, color: palette.textSecondary),
            tooltip: 'Open in Full Screen',
            onPressed: () => _openFullScreen(context),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(CozyPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_rounded, color: palette.error, size: 40),
            const SizedBox(height: 8),
            Text(
              'Failed to load ECG trace image',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

