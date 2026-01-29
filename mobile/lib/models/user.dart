class User {
  final int id;
  final String email;
  final String role;
  final int coins;
  final int xp;
  final int level;
  final int streakCount;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.coins,
    required this.xp, 
    required this.level,
    required this.streakCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'] ?? 'student',
      coins: json['coins'] ?? 0,
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      streakCount: json['streak_count'] ?? 0,
    );
  }
}
