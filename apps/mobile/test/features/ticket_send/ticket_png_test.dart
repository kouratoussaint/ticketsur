import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/features/ticket_send/presentation/ticket_png.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';
import 'package:ticketsur/features/ticket_templates/presentation/ticket_artwork.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/l10n/l10n.dart';

import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_ticket_repository.dart';

void main() {
  testWidgets('image du ticket rendue hors écran avec son modèle', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: TicketSurTheme.light(),
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Builder(
          builder: (c) {
            context = c;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    final art = TicketArt(
      event: testEvent(title: 'Gala'),
      organizationName: 'Faso Événements',
      info: const {'t1': (categoryId: 'cat-1', number: 7)},
    );
    // Logo du talon déjà décodé (comme après un aperçu) : le rendu se fait
    // en un seul cadre.
    await tester.runAsync(() => precacheImage(ticketStubLogo, context));
    final future = renderTicketPng(
      context,
      art: art,
      ticket: TicketSecret(
        ticketId: 't1',
        reference: 'TS-AAAA-0001',
        token: fakeToken(1),
        categoryName: 'VIP',
        holderName: 'Awa',
      ),
      pixelRatio: 1,
    );
    // Le cadre qui construit et peint le ticket hors écran.
    await tester.pump();
    await tester.pump();
    final png = (await tester.runAsync(() => future))!;

    expect(png.take(4), [0x89, 0x50, 0x4E, 0x47]);
    // En-tête IHDR : largeur et hauteur en octets 16 à 23 (gros-boutiste).
    final header = ByteData.sublistView(Uint8List.fromList(png));
    // Format 2,4:1 à la taille de référence.
    expect(header.getUint32(16), 1080);
    expect(header.getUint32(20), 450);
    // La couche temporaire est retirée.
    await tester.pump();
    expect(find.text('TS-AAAA-0001'), findsNothing);
  });
}
