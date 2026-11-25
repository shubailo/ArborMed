import 'dart:convert';
import 'dart:typed_data';
import 'package:arbor_med/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('uploads a memory-backed image with a compatible MIME and original filename', () async {
    final api = ApiService()..setToken('fixture-token');
    int requests = 0;
    api.setHttpClient(MockClient((request) async {
      requests++;
      expect(request.headers['authorization'], 'Bearer fixture-token');
      expect(request.url.path, '/api/upload');
      final body = latin1.decode(request.bodyBytes);
      expect(body, contains('filename="diagram.GIF"'));
      expect(body.toLowerCase(), contains('content-type: image/gif'));
      expect(body, contains('GIF89a'));
      return http.Response('{"imageUrl":"/uploads/persisted.gif"}',200);
    }));
    addTearDown(() { api.setHttpClient(http.Client()); api.setToken(''); });
    final image = XFile.fromData(Uint8List.fromList(ascii.encode('GIF89a')),name:'diagram.GIF', path:'diagram.GIF');
    expect(await api.uploadImage(image), '/uploads/persisted.gif');
    expect(requests, 1);
  });
}
