import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'download_helper.dart';

class DownloadHelperMobile implements DownloadHelper {
  @override
  Future<void> download(List<int> bytes, String filename, String mimeType) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);
    // Ideally we'd use open_file here to open it.
    print('File saved to: ${file.path}');
  }
}

DownloadHelper getHelper() => DownloadHelperMobile();
