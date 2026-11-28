import 'package:arbor_med/widgets/cozy/floating_medical_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app({required bool reduce, Color color = Colors.blue}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width:100, height:90,
          child: FloatingMedicalIcons(color:color))),
    ),
  );

  testWidgets('reduced motion paints static icons and refreshes their color', (tester) async {
    await tester.pumpWidget(app(reduce:true));
    await tester.pumpAndSettle(const Duration(milliseconds:50), EnginePhase.sendSemanticsUpdate, const Duration(seconds:1));
    expect(find.byType(Align), findsNWidgets(15));
    await tester.pumpWidget(app(reduce:true,color:Colors.red));
    final icons = tester.widgetList<Icon>(find.byType(Icon));
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(icons.length + images.length, greaterThanOrEqualTo(15));
    for (final icon in icons) {
      expect(icon.color, anyOf(Colors.red, Colors.red.withValues(alpha:0.5)));
    }
    for (final image in images) expect(image.color, Colors.red.withValues(alpha:0.5));
  });

  testWidgets('cycling icons remains bounded and disposal cancels the timer', (tester) async {
    await tester.pumpWidget(app(reduce:false));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(minutes:10));
      expect(find.byType(Align).evaluate().length, lessThanOrEqualTo(30));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes:10));
    expect(tester.takeException(), isNull);
  });
}
