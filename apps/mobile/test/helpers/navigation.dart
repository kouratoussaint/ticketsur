import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';

/// Ouvre la liste des événements (sous l'onglet « Organiser » depuis la
/// refonte Tikéo, sans entrée propre dans la barre).
Future<void> openEventsList(WidgetTester tester) async {
  GoRouter.of(tester.element(find.byType(NavigationBar))).go(AppRoutes.events);
  await tester.pumpAndSettle();
}
