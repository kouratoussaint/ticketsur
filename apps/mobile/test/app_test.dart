import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/scanner/presentation/verdict_preview_page.dart';

void main() {
  testWidgets('démarre sur l’accueil TicketSûr et ouvre la galerie', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TicketSurApp()));
    await tester.pumpAndSettle();

    expect(find.text('Votre événement en un clic'), findsOneWidget);
    final signIn = tester.widget<FilledButton>(
      find.byKey(const Key('welcome-sign-in')),
    );
    expect(
      signIn.onPressed,
      isNull,
      reason: 'connexion en attente de Supabase',
    );

    await tester.tap(find.byKey(const Key('welcome-verdict-preview')));
    await tester.pumpAndSettle();
    expect(find.byType(VerdictPreviewPage), findsOneWidget);
    expect(find.text('Ticket déjà utilisé'), findsOneWidget);
  });
}
