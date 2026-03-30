import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'download_helper.dart';

class DownloadHelperWeb implements DownloadHelper {
  @override
  Future<void> download(List<int> bytes, String filename, String mimeType) async {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

DownloadHelper getHelper() => DownloadHelperWeb();
