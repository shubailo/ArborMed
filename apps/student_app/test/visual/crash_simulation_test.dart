import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/widgets/analytics/activity_chart.dart';
import 'package:arbor_med/widgets/profile/activity_view.dart';
import 'package:arbor_med/services/stats_provider.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ActivityChart stress test - rapid data updates + touch', (WidgetTester tester) async {
    final themeService = ThemeService();
    
    // 1. Create initial data
    final data1 = List.generate(7, (i) => ActivityData(
      date: DateTime.now().subtract(Duration(days: i)),
      count: 5,
      correctCount: 3,
    ));

    final data2 = List.generate(3, (i) => ActivityData(
      date: DateTime.now().subtract(Duration(days: i)),
      count: 10,
      correctCount: 8,
    ));

    Widget buildTestWidget(List<ActivityData> data) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: ActivityChart(data: data, timeframe: ActivityTimeframe.week),
            ),
          ),
        ),
      );
    }

    // 2. Build the chart
    await tester.pumpWidget(buildTestWidget(data1));
    await tester.pumpAndSettle();

    // 3. Simulate a touch at a position that would be valid for data1 (index 6)
    // but invalid for data2 (max index 2).
    final center = tester.getCenter(find.byType(ActivityChart));
    final rightSide = center.translate(100, 0); 

    // 4. Start rapid updates & touches
    for (int i = 0; i < 10; i++) {
      // Toggle data
      await tester.pumpWidget(buildTestWidget((i % 2 == 0) ? data2 : data1));
      
      // Trigger a tap while animating or just after update
      await tester.tapAt(rightSide);
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 100));
    }

    // If we reached here without a RangeError, the test passed!
    expect(find.byType(ActivityChart), findsOneWidget);
  });
}
