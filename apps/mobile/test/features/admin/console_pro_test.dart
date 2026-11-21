import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/console_announcements_page.dart';
import 'package:ticketsur/features/admin/presentation/console_page.dart';
import 'package:ticketsur/features/announcements/domain/announcement.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/support/data/supabase_support_repository.dart';
import 'package:ticketsur/features/support/domain/support.dart';
import 'package:ticketsur/features/support/presentation/support_templates.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_support_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'admin@exemple.bf');

  test('réponse type : remplace un champ vide, sinon s’ajoute', () {
    expect(insertTemplate('  ', 'Bonjour.'), 'Bonjour.');
    expect(insertTemplate('Merci ', 'Bonjour.'), 'Merci\n\nBonjour.');
    supabase.PostgrestException error(String message) =>
        supabase.PostgrestException(message: message);
    expect(
      mapSupportError(error('support_templates_limit')),
      SupportFailure.limit,
    );
    expect(
      mapSupportError(error('support_template_title_invalid')),
      SupportFailure.invalid,
    );
    expect(
      DailyStat.fromJson(const {
        'day': '2030-06-01',
        'accounts': 2,
        'tickets_issued': 40,
      }).valueOf(DailyMetric.tickets),
      40,
    );
  });

  late FakeSupportRepository support;
  late FakeAnnouncementRepository announcements;
  late FakeAdminRepository admin;

  setUp(() {
    support = FakeSupportRepository(requests: [supportRequest()])
      ..adminMode = true;
    announcements = FakeAnnouncementRepository();
    admin = FakeAdminRepository(admin: true);
  });

  Future<void> openApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(
          auth: FakeAuthRepository(user: user),
          organizations: FakeOrganizationRepository([testOrganization]),
          support: support,
          announcements: announcements,
          admin: admin,
        ),
        child: const TicketSurApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> go(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Bouton du bas d'une liste paresseuse (formulaire d'annonce).
  Future<void> publish(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('announcement-publish'));
    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ConsoleAnnouncementFormPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('annonce programmée : demain 9 h, puis modifiée', (tester) async {
    await openApp(tester);
    await go(tester, AppRoutes.consoleAnnouncements);
    await tester.tap(find.byKey(const Key('console-announcement-new')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('announcement-title')),
      'Maintenance',
    );
    await tester.enterText(
      find.byKey(const Key('announcement-body')),
      'Coupure de 2 h à 3 h.',
    );
    await tapVisible(
      tester,
      find.byKey(const Key('announcement-audience-promoters')),
    );
    await tapVisible(tester, find.byKey(const Key('announcement-important')));
    await tapVisible(tester, find.byKey(const Key('announcement-start-later')));
    expect(find.byKey(const Key('announcement-start-hint')), findsOneWidget);
    await publish(tester);

    final published = announcements.published!;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 9);
    expect(published.startsAt, tomorrow);
    // Durée d'une semaine comptée depuis le début.
    expect(published.endsAt, tomorrow.add(const Duration(days: 7)));
    expect(find.textContaining('Annonce programmée pour le'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    // Retour à la liste : « Programmée », modifiable.
    expect(find.text('Programmée'), findsOneWidget);
    await tapVisible(
      tester,
      find.byKey(const Key('console-announcement-edit-pub-0')),
    );
    await tester.enterText(
      find.byKey(const Key('announcement-title')),
      'Maintenance prévue',
    );
    await tapVisible(tester, find.byKey(const Key('announcement-start-now')));
    await publish(tester);
    expect(announcements.updated, [('pub-0', null)]);
    expect(find.text('Maintenance prévue'), findsOneWidget);
    expect(find.text('Programmée'), findsNothing);
  });

  testWidgets('réponses types : créer, insérer dans une réponse, supprimer', (
    tester,
  ) async {
    await openApp(tester);
    await go(tester, AppRoutes.consoleSupport);
    await tapVisible(
      tester,
      find.byKey(const Key('console-support-templates')),
    );
    expect(
      find.byKey(const Key('support-templates-page-empty')),
      findsOneWidget,
    );
    await tapVisible(tester, find.byKey(const Key('support-template-new')));
    await tester.enterText(
      find.byKey(const Key('support-template-title')),
      'Mot de passe',
    );
    await tester.enterText(
      find.byKey(const Key('support-template-body')),
      'Touchez « Mot de passe oublié ».',
    );
    await tapVisible(tester, find.byKey(const Key('support-template-save')));
    expect(support.calls, contains('saveTemplate:tpl-1'));
    expect(find.byKey(const Key('support-template-row-tpl-1')), findsOneWidget);

    // Le message de confirmation passe.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    // Dans le fil d'une demande : insérée puis modifiable.
    await go(tester, AppRoutes.consoleSupportThread('r1'));
    await tester.enterText(find.byKey(const Key('support-reply')), 'Bonjour,');
    await tapVisible(tester, find.byKey(const Key('support-templates')));
    await tester.tap(find.byKey(const Key('support-template-tpl-1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('support-reply')))
          .controller!
          .text,
      'Bonjour,\n\nTouchez « Mot de passe oublié ».',
    );

    await go(tester, AppRoutes.consoleSupportTemplates);
    await tapVisible(
      tester,
      find.byKey(const Key('support-template-delete-tpl-1')),
    );
    await tester.tap(find.byKey(const Key('support-template-delete-confirm')));
    await tester.pumpAndSettle();
    expect(support.calls, contains('deleteTemplate:tpl-1'));
    expect(
      find.byKey(const Key('support-templates-page-empty')),
      findsOneWidget,
    );
  });

  testWidgets('vue d’ensemble : courbe des 30 jours, une mesure à la fois', (
    tester,
  ) async {
    admin.stats = [
      for (var i = 0; i < 30; i++)
        DailyStat(
          day: DateTime.utc(2030, 6).add(Duration(days: i)),
          accounts: 1,
          ticketsIssued: i == 29 ? 12 : 3,
        ),
    ];
    await openApp(tester);
    await go(tester, AppRoutes.console);
    final total = find.byKey(const Key('console-trend-total'));
    await tester.scrollUntilVisible(
      total,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ConsolePage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.widget<Text>(total).data, '30 sur 30 jours');
    expect(find.byKey(const Key('console-trend-chart')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('console-trend-tickets')));
    expect(tester.widget<Text>(total).data, '99 sur 30 jours');
    expect(find.text('Aujourd’hui : 12'), findsNothing);
    expect(find.text("Aujourd'hui : 12"), findsOneWidget);
  });

  test('annonce : état « programmée » lu du serveur', () {
    final a = Announcement.fromJson(const {
      'id': 'a',
      'title': 'T',
      'body': 'B',
      'level': 'info',
      'starts_at': '2030-06-01T09:00:00Z',
      'scheduled': true,
      'active': false,
    });
    expect(a.scheduled, isTrue);
  });
}
