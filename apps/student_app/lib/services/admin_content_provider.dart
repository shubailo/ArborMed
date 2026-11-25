import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'api_service.dart';
import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/features/analytics/models/quote.dart';

/// Manages admin content operations: quotes CRUD, image uploads,
/// icon management, and translation.
class AdminContentProvider with ChangeNotifier {
  final AuthProvider authProvider;

  AdminContentProvider(this.authProvider);

  ApiService get apiService => authProvider.apiService;

  // --- State ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _quoteLoadFailed = false;
  bool get quoteLoadFailed => _quoteLoadFailed;
  int _quoteRequest = 0;

  List<Quote> _adminQuotes = [];
  List<Quote> get adminQuotes => _adminQuotes;

  Quote? _currentQuote;
  Quote? get currentQuote => _currentQuote;

  List<String> _uploadedIcons = [];
  List<String> get uploadedIcons => _uploadedIcons;

  // --- Quote CRUD ---

  Future<void> fetchAdminQuotes() async {
    final request = ++_quoteRequest;
    _isLoading = true;
    _quoteLoadFailed = false;
    notifyListeners();
    try {
      final data = await apiService.get(ApiEndpoints.quizAdminQuotes);
      if (request != _quoteRequest) return;
      if (data is! List) throw const FormatException('Expected a quote list');
      _adminQuotes = data.map((e) => Quote.fromJson(e)).toList();
    } catch (e) {
      if (request != _quoteRequest) return;
      _quoteLoadFailed = true;
      debugPrint('Error fetching admin quotes: $e');
    } finally {
      if (request == _quoteRequest) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createQuote(String textEn, String textHu, String author,
      {String? titleEn,
      String? titleHu,
      String? iconName,
      String? customIconUrl}) async {
    try {
      await apiService.post(ApiEndpoints.quizAdminQuotes, {
        'text_en': textEn,
        'text_hu': textHu,
        'author': author,
        'title_en': titleEn,
        'title_hu': titleHu,
        'icon_name': iconName,
        'custom_icon_url': customIconUrl,
      });
      await fetchAdminQuotes();
      return true;
    } catch (e) {
      debugPrint('Error creating quote: $e');
      return false;
    }
  }

  Future<bool> updateQuote(int id, String textEn, String textHu, String author,
      {String? titleEn,
      String? titleHu,
      String? iconName,
      String? customIconUrl}) async {
    try {
      await apiService.put('${ApiEndpoints.quizAdminQuotes}/$id', {
        'text_en': textEn,
        'text_hu': textHu,
        'author': author,
        'title_en': titleEn,
        'title_hu': titleHu,
        'icon_name': iconName,
        'custom_icon_url': customIconUrl,
      });
      await fetchAdminQuotes();
      return true;
    } catch (e) {
      debugPrint('Error updating quote: $e');
      return false;
    }
  }

  Future<bool> deleteQuote(int id) async {
    try {
      await apiService.delete('${ApiEndpoints.quizAdminQuotes}/$id');
      await fetchAdminQuotes();
      return true;
    } catch (e) {
      debugPrint('Error deleting quote: $e');
      return false;
    }
  }

  Future<void> fetchCurrentQuote() async {
    try {
      final data = await apiService.get(ApiEndpoints.quizSingleQuote);
      _currentQuote = Quote.fromJson(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching current quote: $e');
    }
  }

  // --- Image & Icon Management ---

  Future<String?> uploadImage(XFile file, {String? folder}) async {
    return ApiService().uploadImage(file, folder: folder);
  }

  Future<void> fetchUploadedIcons() async {
    try {
      final data =
          await apiService.get('${ApiEndpoints.apiUpload}?folder=icons');
      _uploadedIcons = List<String>.from(data['images']);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching uploaded icons: $e');
    }
  }

  Future<bool> deleteUploadedIcon(String iconUrl) async {
    try {
      final filename = iconUrl.split('/').last;
      final stored = Uri.parse(iconUrl).path.startsWith('/uploads/stored/');
      await apiService.delete('${ApiEndpoints.apiUpload}/$filename?folder=icons&stored=$stored');
      _uploadedIcons.removeWhere((url) => url.endsWith(filename));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting icon: $e');
      return false;
    }
  }

  // --- Translation ---

  Future<String?> translateText(
      String text, String sourceLang, String targetLang) async {
    try {
      final data = await apiService.post(ApiEndpoints.quizTranslate, {
        'text': text,
        'from': sourceLang,
        'to': targetLang,
      });
      return data['translated'];
    } catch (e) {
      debugPrint('Error translating text: $e');
      return null;
    }
  }

  void resetState() {
    ++_quoteRequest;
    _quoteLoadFailed = false;
    _isLoading = false;
    _adminQuotes = [];
    _currentQuote = null;
    _uploadedIcons = [];
    notifyListeners();
  }
}
