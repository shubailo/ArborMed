import 'dart:convert';
import 'package:arbor_med/services/session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  test('read sees a completed sign-in when the preferences cache predates it',
      () async {
    SharedPreferences.setMockInitialValues({'arbormed_signed_out': true});
    final previous = await SharedPreferences.getInstance();
    expect(previous.getBool('arbormed_signed_out'), true);
    const keys = FlutterSecureStorage();
    await keys.write(
        key: 'arbormed_session',
        value: jsonEncode({
          'token': 'current',
          'user': {'id': 2}
        }));
    await SharedPreferencesStorePlatform.instance
        .remove('flutter.arbormed_signed_out');
    expect((await SessionStorage.read())?['token'], 'current');
    expect(await keys.read(key: 'arbormed_session'), isNotNull);
  });
  test('a background save observes sign-out from another tab', () async {
    await SessionStorage.save('first', 'refresh', {'id': 1});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('arbormed_signed_out'), isNull);
    await SharedPreferencesStorePlatform.instance
        .setValue('Bool', 'flutter.arbormed_signed_out', true);
    await SessionStorage.save('late', 'refresh', {'id': 1},
        replaceSession: false);
    expect(await SessionStorage.read(), isNull);
    expect(prefs.getBool('arbormed_signed_out'), isTrue);
  });

  test('a background save can update only the current login', () async {
    await SessionStorage.save('first', 'old-refresh', {'id': 1});
    await SessionStorage.save('fresh', 'new-refresh', {'id': 1});
    await SessionStorage.save('late', 'old-refresh', {'id': 1},
        replaceSession: false, invalidateOnFailure: true);
    expect((await SessionStorage.read())?['token'], 'fresh');
    await SessionStorage.save('rotated-access', 'new-refresh', {'id': 1},
        replaceSession: false);
    expect((await SessionStorage.read())?['token'], 'rotated-access');
  });

  test('a background save preserves a secure-only sign-out marker', () async {
    const keys = FlutterSecureStorage();
    await keys.write(key: 'arbormed_session', value: 'arbormed_signed_out');
    await SessionStorage.save('late', 'old-refresh', {'id': 1},
        replaceSession: false);
    expect(await keys.read(key: 'arbormed_session'), 'arbormed_signed_out');
    expect(await SessionStorage.read(), isNull);
  });

  test('invalid replacement data leaves the last valid session intact',
      () async {
    await SessionStorage.save('first', null, {'id': 1});
    for (final invalid in [
      <String, dynamic>{},
      {'id': 0},
      {'id': 2147483648}
    ]) {
      await expectLater(
          SessionStorage.save('second', null, invalid, replaceSession: true),
          throwsFormatException);
      expect((await SessionStorage.read())?['token'], 'first');
    }
    await expectLater(
        SessionStorage.save('', null, {'id': 2}, replaceSession: true),
        throwsFormatException);
    expect((await SessionStorage.read())?['token'], 'first');
  });
  test('queued writes persist the profile snapshot presented by the caller',
      () async {
    final user = {'id': 1, 'display_name': 'At submission'};
    final write = SessionStorage.save('first', null, user);
    user['display_name'] = 'Later mutation';
    await write;
    expect((await SessionStorage.read())?['user']['display_name'],
        'At submission');
  });
  test('incomplete legacy sign-in records do not leave orphaned credentials',
      () async {
    SharedPreferences.setMockInitialValues({
      'refresh_token': 'orphan',
      'auth_token': 'unused',
      'theme_mode_enum': 1
    });
    expect(await SessionStorage.read(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'theme_mode_enum'});
  });
}
