import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'download_helper.dart';

class WebDownloadHelper implements DownloadHelper {
  @override
  Future<void> download(List<int> bytes, String filename, String mimeType) async {
    final Uint8List uint8List = Uint8List.fromList(bytes);
    final blob = web.Blob([uint8List.toJS].toJS, web.BlobPropertyBag(type: mimeType));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}

DownloadHelper getDownloadHelper() => WebDownloadHelper();
