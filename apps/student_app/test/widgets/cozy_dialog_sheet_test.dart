import 'package:arbor_med/services/theme_service.dart';
import 'package:arbor_med/widgets/cozy/cozy_dialog_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('a sheet stays inside the safe area and outside taps close once', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 310));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var closes = 0;
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top:40,bottom:20),
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: CozyDialogSheet(
          onTapOutside: () => closes++,
          child: const SizedBox(height:300, child: SingleChildScrollView(
              child: Text('Available actions and placement details'))),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds:350));
    final card = tester.getRect(find.byType(ScaleTransition).first);
    expect(card.top,greaterThanOrEqualTo(40));
    expect(card.bottom,lessThanOrEqualTo(290));
    await tester.tapAt(const Offset(2,2));
    await tester.tapAt(const Offset(2,2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds:350));
    expect(closes,1);
  });
}
