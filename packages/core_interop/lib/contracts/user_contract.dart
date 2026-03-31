class UserData {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isEmailVerified;

  const UserData({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isEmailVerified,
  });
}

abstract class UserContract {
  UserData? get currentUser;
  Future<void> updateDisplayName(String name);
}
