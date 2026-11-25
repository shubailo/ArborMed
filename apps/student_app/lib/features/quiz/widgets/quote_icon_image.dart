import '../../../services/api_service.dart';

class QuoteIconImage {
  final Uri uri;
  final double scale;
  final bool showBackground;

  const QuoteIconImage._(this.uri, this.scale, this.showBackground);

  static QuoteIconImage? parse(String? value) {
    if (value == null || value.isEmpty || value == 'random_gallery') {
      return null;
    }
    try {
      final path = Uri.parse(value);
      if (!path.hasScheme && (path.hasAuthority || path.path.isEmpty)) {
        return null;
      }
      final uri = Uri.parse(ApiService.baseUrl).resolveUri(path);
      if (!{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) {
        return null;
      }
      final params = uri.queryParameters;
      final scale = double.tryParse(params['scale'] ?? '');
      // The gallery slider supports 50–250%. Invalid stored values use its default.
      final bounded = scale != null && scale.isFinite && scale > 0
          ? scale.clamp(0.5, 2.5).toDouble()
          : 1.0;
      return QuoteIconImage._(
          uri, bounded, params['bg'] == null || params['bg'] == 'true');
    } on FormatException {
      return null;
    }
  }
}
