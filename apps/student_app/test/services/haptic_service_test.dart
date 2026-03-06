import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/services/haptic_service.dart';
import 'package:vibration_platform_interface/vibration_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVibrationPlatform extends VibrationPlatform
    with MockPlatformInterfaceMixin {
  bool hasVibratorMock = true;
  bool hasCustomVibrationsMock = true;
  bool throwsError = false;

  final methodLog = <String>[];
  final argLog = <Map<String, dynamic>>[];

  @override
  Future<bool> hasVibrator() async {
    methodLog.add('hasVibrator');
    if (throwsError) throw Exception('Mock error');
    return hasVibratorMock;
  }

  @override
  Future<bool> hasCustomVibrationsSupport() async {
    methodLog.add('hasCustomVibrationsSupport');
    if (throwsError) throw Exception('Mock error');
    return hasCustomVibrationsMock;
  }

  @override
  Future<void> vibrate({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
    double sharpness = 0.5,
  }) async {
    methodLog.add('vibrate');
    argLog.add({
      'pattern': pattern,
      'intensities': intensities,
    });
    if (throwsError) throw Exception('Mock error');
  }

  void clearLogs() {
    methodLog.clear();
    argLog.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CozyHaptics', () {
    final hapticLog = <MethodCall>[];
    late MockVibrationPlatform mockVibrationPlatform;

    setUp(() {
      hapticLog.clear();
      mockVibrationPlatform = MockVibrationPlatform();
      VibrationPlatform.instance = mockVibrationPlatform;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'HapticFeedback.vibrate') {
            hapticLog.add(methodCall);
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('lightTap calls HapticFeedback.selectionClick', () async {
      await CozyHaptics.lightTap();
      expect(hapticLog.length, 1);
      expect(hapticLog.first.arguments, 'HapticFeedbackType.selectionClick');
    });

    test('mediumTap calls HapticFeedback.lightImpact', () async {
      await CozyHaptics.mediumTap();
      expect(hapticLog.length, 1);
      expect(hapticLog.first.arguments, 'HapticFeedbackType.lightImpact');
    });

    test('heavyImpact calls HapticFeedback.heavyImpact', () async {
      await CozyHaptics.heavyImpact();
      expect(hapticLog.length, 1);
      expect(hapticLog.first.arguments, 'HapticFeedbackType.heavyImpact');
    });

    test('celebrate calls HapticFeedback.heavyImpact 3 times', () async {
      await CozyHaptics.celebrate();
      expect(hapticLog.length, 3);
      expect(hapticLog[0].arguments, 'HapticFeedbackType.heavyImpact');
      expect(hapticLog[1].arguments, 'HapticFeedbackType.heavyImpact');
      expect(hapticLog[2].arguments, 'HapticFeedbackType.heavyImpact');
    });

    group('success', () {
      test('with custom vibrations uses specific pattern', () async {
        await CozyHaptics.success();

        expect(mockVibrationPlatform.methodLog,
            ['hasVibrator', 'hasCustomVibrationsSupport', 'vibrate']);
        expect(mockVibrationPlatform.argLog.first['pattern'], [0, 40, 120, 20]);
        expect(
            mockVibrationPlatform.argLog.first['intensities'], [0, 128, 0, 64]);
        expect(hapticLog.isEmpty, true);
      });

      test('without custom vibrations falls back to HapticFeedback', () async {
        mockVibrationPlatform.hasCustomVibrationsMock = false;
        await CozyHaptics.success();

        expect(hapticLog.length, 2);
        expect(hapticLog[0].arguments, 'HapticFeedbackType.mediumImpact');
        expect(hapticLog[1].arguments, 'HapticFeedbackType.lightImpact');
      });

      test('without vibrator falls back to HapticFeedback.mediumImpact',
          () async {
        mockVibrationPlatform.hasVibratorMock = false;
        await CozyHaptics.success();

        expect(hapticLog.length, 1);
        expect(hapticLog[0].arguments, 'HapticFeedbackType.mediumImpact');
      });

      test('on exception falls back to HapticFeedback.mediumImpact', () async {
        mockVibrationPlatform.throwsError = true;
        await CozyHaptics.success();

        expect(hapticLog.length, 1);
        expect(hapticLog[0].arguments, 'HapticFeedbackType.mediumImpact');
      });
    });

    group('error', () {
      test('with custom vibrations uses specific pattern', () async {
        await CozyHaptics.error();

        expect(mockVibrationPlatform.methodLog,
            ['hasVibrator', 'hasCustomVibrationsSupport', 'vibrate']);
        expect(
            mockVibrationPlatform.argLog.first['pattern'], [0, 100, 50, 100]);
        expect(mockVibrationPlatform.argLog.first['intensities'],
            [0, 255, 0, 255]);
        expect(hapticLog.isEmpty, true);
      });

      test('without custom vibrations falls back to HapticFeedback', () async {
        mockVibrationPlatform.hasCustomVibrationsMock = false;
        await CozyHaptics.error();

        expect(hapticLog.length, 2);
        expect(hapticLog[0].arguments, 'HapticFeedbackType.heavyImpact');
        expect(hapticLog[1].arguments, 'HapticFeedbackType.heavyImpact');
      });

      test('without vibrator falls back to HapticFeedback.heavyImpact',
          () async {
        mockVibrationPlatform.hasVibratorMock = false;
        await CozyHaptics.error();

        expect(hapticLog.length, 1);
        expect(hapticLog[0].arguments, 'HapticFeedbackType.heavyImpact');
      });

      test('on exception falls back to HapticFeedback.heavyImpact', () async {
        mockVibrationPlatform.throwsError = true;
        await CozyHaptics.error();

        expect(hapticLog.length, 1);
        expect(hapticLog[0].arguments, 'HapticFeedbackType.heavyImpact');
      });
    });
  });
}
