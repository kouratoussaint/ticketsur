import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/status_chip.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';

void main() {
  for (final (name, tints) in [
    ('clair', TikeoTints.light),
    ('sombre', TikeoTints.dark),
  ]) {
    group('teintes, thème $name', () {
      for (final MapEntry(key: tint, value: colors) in tints.all.entries) {
        test('$tint : texte sur fond ≥ 4,5:1', () {
          expect(
            contrastRatio(colors.text, colors.background),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
    });
  }

  test('les thèmes portent leurs teintes', () {
    expect(TicketSurTheme.light().extension<TikeoTints>(), TikeoTints.light);
    expect(TicketSurTheme.dark().extension<TikeoTints>(), TikeoTints.dark);
  });

  test('pastille de type sur photo : texte blanc ≥ 4,5:1', () {
    for (final color in const [
      TikeoKindColors.concert,
      TikeoKindColors.conference,
      TikeoKindColors.training,
      TikeoKindColors.sport,
      TikeoKindColors.worship,
      TikeoKindColors.wedding,
      TikeoKindColors.gala,
      TikeoKindColors.other,
    ]) {
      expect(
        contrastRatio(TicketSurColors.white, color),
        greaterThanOrEqualTo(4.5),
        reason: '$color',
      );
    }
  });

  test('bouton principal et barre de navigation lisibles', () {
    for (final background in [TicketSurColors.mint, TikeoColors.mintBright]) {
      expect(
        contrastRatio(TicketSurColors.navy, background),
        greaterThanOrEqualTo(4.5),
      );
    }
    expect(
      contrastRatio(TicketSurColors.mint, TicketSurColors.navy),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(TikeoColors.mutedDark, TicketSurColors.navy),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('statuts de ticket : couleurs des maquettes', () {
    const t = TikeoTints.light;
    expect(ticketStatusTint(TicketStatus.redeemed, t), t.green);
    expect(ticketStatusTint(TicketStatus.issued, t), t.blue);
    expect(ticketStatusTint(TicketStatus.revoked, t), t.red);
    expect(ticketStatusTint(TicketStatus.expired, t), t.gray);
    expect(
      ticketStatusStyle(TicketStatus.redeemed, t).icon,
      Icons.check_circle_rounded,
    );
  });

  test('statuts d’événement : couleurs des maquettes', () {
    const t = TikeoTints.light;
    expect(
      eventStatusStyle(EventStatus.inProgress).background,
      t.live.background,
    );
    expect(eventStatusStyle(EventStatus.published).foreground, t.blue.text);
    expect(eventStatusStyle(EventStatus.draft).icon, t.amber.icon);
    expect(eventStatusStyle(EventStatus.closed).background, t.gray.background);
    expect(eventStatusStyle(EventStatus.cancelled).foreground, t.red.text);
    expect(
      eventStatusStyle(EventStatus.published, Brightness.dark).foreground,
      TikeoTints.dark.blue.text,
    );
  });

  testWidgets('pastille : 28 de haut, teinte de sa tonalité', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TicketSurTheme.light(),
        home: const Scaffold(
          body: Center(
            child: StatusChip(
              label: 'Utilisé',
              tone: StatusTone.positive,
              icon: Icons.check_circle_rounded,
            ),
          ),
        ),
      ),
    );
    final chip = find.byType(StatusChip);
    expect(tester.getSize(chip).height, greaterThanOrEqualTo(28));
    final text = tester.widget<Text>(find.text('Utilisé'));
    expect(text.style?.color, TikeoTints.light.green.text);
    expect(text.style?.fontWeight, FontWeight.w700);
  });
}
