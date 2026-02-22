import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'download_helper.dart';

class NativeDownloadHelper implements DownloadHelper {
  @override
  Future<void> download(List<int> bytes, String filename, String mimeType) async {
     String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save File',
          fileName: filename,
          type: FileType.any, 
        );

     if (outputFile != null) {
       final file = File(outputFile);
       await file.writeAsBytes(bytes);
     }
  }
}

DownloadHelper getDownloadHelper() => NativeDownloadHelper();
