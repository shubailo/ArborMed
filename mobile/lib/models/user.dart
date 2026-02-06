class User {
  final int id;
  final String? email;
  final String? username;
  final String? displayName;
  final String role;
  final int coins;
  final int xp;
  final int level;
  final int streakCount;
  final int longestStreak;
  final bool isEmailVerified;
  final String? friendshipStatus; // 'none', 'pending', 'colleague', 'request_sent', 'request_received'

  User({
    required this.id,
    this.email,
    this.username,
    this.displayName,
    required this.role,
    required this.coins,
    required this.xp, 
    required this.level,
    required this.streakCount,
    this.longestStreak = 0,
    this.isEmailVerified = false,
    this.friendshipStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      displayName: json['display_name'],
      role: json['role'] ?? 'student',
      coins: json['coins'] ?? 0,
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      streakCount: json['streak_count'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      isEmailVerified: json['is_email_verified'] ?? true, // Defaulting to true for non-auth paths if missing
      friendshipStatus: json['friendshipStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'role': role,
      'coins': coins,
      'xp': xp,
      'level': level,
      'streak_count': streakCount,
      'longest_streak': longestStreak,
      'is_email_verified': isEmailVerified,
      'friendshipStatus': friendshipStatus,
    };
  }
}
