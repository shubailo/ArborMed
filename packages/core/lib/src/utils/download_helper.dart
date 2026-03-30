import 'dart:async';
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_mobile.dart';

/// Abstract class defined as a placeholder for platform-specific implementations.
abstract class DownloadHelper {
  Future<void> download(List<int> bytes, String filename, String mimeType);
}

/// Global instance of DownloadHelper.
final DownloadHelper downloadHelper = getHelper();
