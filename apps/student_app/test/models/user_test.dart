import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/core/models/user.dart';

void main() {
  group('User Model', () {
    test('clinical rounds use the server UTC day across local midnight', () {
      final beforeUtcMidnight = DateTime.parse('2026-03-30T00:30:00+02:00');
      for (final day in ['2026-03-29T00:00:00.000Z', '2026-03-29']) {
        final user = User.fromJson({'id': 1, 'last_rounds_date': day});
        expect(user.completedRoundsOn(beforeUtcMidnight), isTrue);
        expect(user.completedRoundsOn(DateTime.utc(2026, 3, 30)), isFalse);
      }
      expect(User.fromJson({'id': 1}).completedRoundsOn(beforeUtcMidnight), isFalse);
    });

    test('persists only the superadmin capability returned for the current account', () {
      final admin = User.fromJson({'id': 42, 'role': 'admin', 'is_super_admin': true});
      expect(User.fromJson(admin.toJson()).isSuperAdmin, isTrue);
      expect(User.fromJson({'id': 42, 'role': 'admin'}).isSuperAdmin, isFalse);
    });

    test('User instantiation', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        username: 'testuser',
        displayName: 'Test User',
        role: 'admin',
        coins: 100,
        xp: 500,
        level: 5,
        streakCount: 3,
        longestStreak: 10,
        isEmailVerified: true,
        friendshipStatus: 'colleague',
      );

      expect(user.id, 1);
      expect(user.email, 'test@example.com');
      expect(user.username, 'testuser');
      expect(user.displayName, 'Test User');
      expect(user.role, 'admin');
      expect(user.coins, 100);
      expect(user.xp, 500);
      expect(user.level, 5);
      expect(user.streakCount, 3);
      expect(user.longestStreak, 10);
      expect(user.isEmailVerified, true);
      expect(user.friendshipStatus, 'colleague');
    });

    test('User.fromJson parses all fields correctly', () {
      final json = {
        'id': 2,
        'email': 'json@example.com',
        'username': 'jsonuser',
        'display_name': 'JSON User',
        'role': 'teacher',
        'coins': 200,
        'xp': 1000,
        'level': 10,
        'streak_count': 5,
        'longest_streak': 15,
        'is_email_verified': true,
        'friendshipStatus': 'pending',
      };

      final user = User.fromJson(json);

      expect(user.id, 2);
      expect(user.email, 'json@example.com');
      expect(user.username, 'jsonuser');
      expect(user.displayName, 'JSON User');
      expect(user.role, 'teacher');
      expect(user.coins, 200);
      expect(user.xp, 1000);
      expect(user.level, 10);
      expect(user.streakCount, 5);
      expect(user.longestStreak, 15);
      expect(user.isEmailVerified, true);
      expect(user.friendshipStatus, 'pending');
    });

    test('User.fromJson applies default values for missing optional fields',
        () {
      final json = {
        'id': 3,
      };

      final user = User.fromJson(json);

      expect(user.id, 3);
      expect(user.email, null);
      expect(user.username, null);
      expect(user.displayName, null);
      expect(user.role, 'student');
      expect(user.coins, 0);
      expect(user.xp, 0);
      expect(user.level, 1);
      expect(user.streakCount, 0);
      expect(user.longestStreak, 0);
      expect(user.isEmailVerified, false);
      expect(user.friendshipStatus, null);
    });

    test('User.toJson serializes correctly', () {
      final user = User(
        id: 4,
        email: 'serialize@example.com',
        username: 'serializeuser',
        displayName: 'Serialize User',
        role: 'student',
        coins: 50,
        xp: 250,
        level: 2,
        streakCount: 1,
        longestStreak: 2,
        isEmailVerified: false,
        friendshipStatus: 'request_sent',
      );

      final json = user.toJson();

      expect(json['id'], 4);
      expect(json['email'], 'serialize@example.com');
      expect(json['username'], 'serializeuser');
      expect(json['display_name'], 'Serialize User');
      expect(json['role'], 'student');
      expect(json['coins'], 50);
      expect(json['xp'], 250);
      expect(json['level'], 2);
      expect(json['streak_count'], 1);
      expect(json['longest_streak'], 2);
      expect(json['is_email_verified'], false);
      expect(json['friendshipStatus'], 'request_sent');
    });
  });
}
