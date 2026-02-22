import 'download_helper_stub.dart'
    if (dart.library.js_interop) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_native.dart';

abstract class DownloadHelper {
  Future<void> download(List<int> bytes, String filename, String mimeType);
}

final DownloadHelper downloadHelper = getDownloadHelper();
