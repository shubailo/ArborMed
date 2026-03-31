enum AuthState { unauthenticated, loading, authenticated }

abstract class AuthContract {
  AuthState get authState;
  Stream<AuthState> get authStateStream;
  String? get currentUserId;
  String? get authToken;
  String? get userRole; // 'student' | 'admin'
}
