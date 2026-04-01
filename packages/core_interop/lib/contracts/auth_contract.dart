enum AuthState { unauthenticated, loading, authenticated }

abstract class AuthContract {
  AuthState get authState;
  Stream<AuthState> get authStateStream;
  String? get currentUserId;
  String? get authToken;
  String? get userRole; // 'student' | 'admin'

  Future<void> login(String identifier, String password);
  Future<void> logout();
  Future<void> register(
    String email, 
    String password, {
    String? username, 
    String? displayName,
  });
  Future<void> verifyEmail(String email, String otp);
  Future<void> requestOTP(String email);
  Future<void> resetPassword(String email, String otp, String newPassword);
}
