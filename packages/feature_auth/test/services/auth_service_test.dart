import 'package:flutter_test/flutter_test.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core_interop/core_interop.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AuthService starts unauthenticated', () {
    final service = AuthService();
    expect(service.authState, AuthState.unauthenticated);
  });
}
