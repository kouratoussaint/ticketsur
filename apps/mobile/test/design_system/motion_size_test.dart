import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';

void main() {
  Widget host({required bool reduced, required double height}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: MotionSize(child: SizedBox(width: 10, height: height)),
      ),
    ),
  );

  testWidgets('animations actives : la taille s’anime', (tester) async {
    await tester.pumpWidget(host(reduced: false, height: 10));
    await tester.pumpWidget(host(reduced: false, height: 100));
    expect(find.byType(AnimatedSize), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getSize(find.byType(MotionSize)).height, lessThan(100));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MotionSize)).height, 100);
  });

  testWidgets('animations réduites : taille immédiate, sans AnimatedSize', (
    tester,
  ) async {
    await tester.pumpWidget(host(reduced: true, height: 10));
    await tester.pumpWidget(host(reduced: true, height: 100));
    expect(find.byType(AnimatedSize), findsNothing);
    expect(tester.getSize(find.byType(MotionSize)).height, 100);
    expect(tester.takeException(), isNull);
  });
}
