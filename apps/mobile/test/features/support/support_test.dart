import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/admin/presentation/console_page.dart';
import 'package:ticketsur/features/announcements/application/announcement_providers.dart';
import 'package:ticketsur/features/announcements/domain/announcement.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/support/data/supabase_support_repository.dart';
import 'package:ticketsur/features/support/domain/support.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_support_repository.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'awa@exemple.bf');

  group('domaine', () {
    test('demande lue depuis le serveur', () {
      final r = SupportRequest.fromJson(const {
        'id': 'r1',
        'subject': 'Paiement',
        'category': 'payment',
        'status': 'answered',
        'unread': true,
        'created_at': '2030-06-01T10:00:00Z',
        'last_message_at': '2030-06-01T11:00:00Z',
        'requester_name': 'Awa',
        'messages': 3,
      });
      expect(r.category, SupportCategory.payment);
      expect(r.status, SupportStatus.answered);
      expect(r.unread, isTrue);
      expect(r.messages, 3);
    });

    test('annonce lue, destinataires inconnus ignorés', () {
      final a = Announcement.fromJson(const {
        'id': 'a1',
        'title': 'Titre',
        'body': 'Corps',
        'level': 'important',
        'starts_at': '2030-06-01T10:00:00Z',
        'ends_at': null,
        'audiences': ['visitors', 'promoters', 'martiens'],
      });
      expect(a.important, isTrue);
      expect(a.endsAt, isNull);
      expect(a.audiences, {
        AnnouncementAudience.visitors,
        AnnouncementAudience.promoters,
      });
    });

    test('erreurs serveur traduites', () {
      supabase.PostgrestException error(String message) =>
          supabase.PostgrestException(message: message, code: '22023');
      expect(
        mapSupportError(error('support_subject_invalid')),
        SupportFailure.invalid,
      );
      expect(mapSupportError(error('support_limit')), SupportFailure.limit);
      expect(
        mapSupportError(error('support_rate_limited')),
        SupportFailure.limit,
      );
      expect(
        mapSupportError(error('support_not_found')),
        SupportFailure.notFound,
      );
      expect(mapSupportError(error('autre')), SupportFailure.unknown);
    });
  });

  group('écrans', () {
    late FakeSupportRepository support;
    late FakeAnnouncementRepository announcements;
    late FakeAdminRepository admin;

    setUp(() {
      support = FakeSupportRepository(
        requests: [
          supportRequest(status: SupportStatus.answered, unread: true),
        ],
      );
      announcements = FakeAnnouncementRepository();
      admin = FakeAdminRepository(admin: true);
    });

    Future<ProviderContainer> openApp(
      WidgetTester tester, {
      AuthUser? signedIn = user,
    }) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: signedIn),
            organizations: FakeOrganizationRepository([testOrganization]),
            support: support,
            announcements: announcements,
            admin: admin,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(TicketSurApp)),
      );
    }

    Future<void> go(WidgetTester tester, String path) async {
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
      await tester.pumpAndSettle();
    }

    Future<void> openTile(WidgetTester tester, String key) async {
      final tile = find.byKey(Key(key));
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ConsolePage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }

    testWidgets('profil : entrée Aide et support avec réponse non lue', (
      tester,
    ) async {
      await openApp(tester);
      await go(tester, AppRoutes.profile);
      final card = find.byKey(const Key('profile-support'));
      await tester.ensureVisible(card);
      expect(find.byKey(const Key('profile-support-unread')), findsOneWidget);
      expect(find.text('1 nouvelle réponse'), findsOneWidget);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('support-request-r1')), findsOneWidget);
      expect(find.byKey(const Key('support-unread-r1')), findsOneWidget);
    });

    testWidgets('nouvelle demande : validation puis envoi et fil ouvert', (
      tester,
    ) async {
      await openApp(tester);
      await go(tester, AppRoutes.support);
      await tester.tap(find.byKey(const Key('support-new')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('support-send')));
      await tester.pumpAndSettle();
      expect(find.text('Entre 3 et 120 caractères.'), findsOneWidget);
      expect(support.created, isNull);

      await tester.tap(find.byKey(const Key('support-category-account')));
      await tester.enterText(
        find.byKey(const Key('support-subject')),
        '  Changer mon adresse  ',
      );
      await tester.enterText(
        find.byKey(const Key('support-body')),
        'Je voudrais changer mon adresse.',
      );
      await tester.tap(find.byKey(const Key('support-send')));
      await tester.pumpAndSettle();
      expect(support.created?.category, SupportCategory.account);
      expect(find.byKey(const Key('support-thread')), findsOneWidget);
      expect(find.text('Je voudrais changer mon adresse.'), findsOneWidget);
    });

    testWidgets('limite atteinte : message clair', (tester) async {
      support.failure = SupportFailure.limit;
      await openApp(tester);
      await go(tester, AppRoutes.support);
      await tester.tap(find.byKey(const Key('support-new')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('support-subject')), 'Aide');
      await tester.enterText(find.byKey(const Key('support-body')), 'Bonjour');
      await tester.tap(find.byKey(const Key('support-send')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('support-form-error')), findsOneWidget);
    });

    testWidgets('fil : répondre puis fermer la demande', (tester) async {
      await openApp(tester);
      await go(tester, AppRoutes.support);
      await tester.tap(find.byKey(const Key('support-request-r1')));
      await tester.pumpAndSettle();
      expect(support.calls, contains('thread:r1'));
      await tester.enterText(
        find.byKey(const Key('support-reply')),
        'Merci, c’est réglé ?',
      );
      await tester.tap(find.byKey(const Key('support-reply-send')));
      await tester.pumpAndSettle();
      expect(find.text('Merci, c’est réglé ?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('support-close')));
      await tester.pumpAndSettle();
      expect(support.calls, contains('close:r1'));
      expect(find.byKey(const Key('support-close')), findsNothing);
    });

    testWidgets('annonce sur l’accueil, masquée et mémorisée', (tester) async {
      announcements = FakeAnnouncementRepository(
        mine: [announcement(important: true)],
      );
      final container = await openApp(tester);
      expect(find.byKey(const Key('announcement-a1')), findsOneWidget);
      expect(find.text('Maintenance samedi'), findsOneWidget);
      await tester.tap(find.byKey(const Key('announcement-dismiss-a1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('announcement-a1')), findsNothing);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getStringList(dismissedAnnouncementsKey),
        ['a1'],
      );
    });

    testWidgets('annonce visible sans compte, sur la présentation', (
      tester,
    ) async {
      announcements = FakeAnnouncementRepository(
        mine: [
          announcement(audiences: const {AnnouncementAudience.visitors}),
        ],
      );
      await openApp(tester, signedIn: null);
      expect(find.byKey(const Key('announcement-a1')), findsOneWidget);
    });

    testWidgets('annonce en échec : rien ne s’affiche', (tester) async {
      announcements = FakeAnnouncementRepository(
        mine: [announcement()],
        failure: AnnouncementFailure.network,
      );
      await openApp(tester);
      expect(find.byKey(const Key('announcement-a1')), findsNothing);
    });

    testWidgets('console : support non lu, filtre, réponse de l’équipe', (
      tester,
    ) async {
      support = FakeSupportRepository(
        requests: [
          supportRequest(unread: true, requesterName: 'Awa'),
          supportRequest(
            id: 'r2',
            subject: 'Question promoteur',
            status: SupportStatus.answered,
            requesterName: 'Ali',
          ),
        ],
      )..adminMode = true;
      await openApp(tester);
      await go(tester, AppRoutes.console);
      expect(find.text('1 demande non lue'), findsOneWidget);
      await openTile(tester, 'console-nav-support');
      expect(find.byKey(const Key('support-request-r1')), findsOneWidget);
      expect(find.byKey(const Key('support-request-r2')), findsNothing);
      expect(find.text('Awa · awa@exemple.bf'), findsOneWidget);

      await tester.tap(find.byKey(const Key('console-support-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('support-request-r2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('support-request-r1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('support-reply')),
        'Nous avons renvoyé votre ticket.',
      );
      await tester.tap(find.byKey(const Key('support-reply-send')));
      await tester.pumpAndSettle();
      expect(find.text('Support Tikéo'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      // Répondue : elle reste visible dans « Toutes », marquée Répondu.
      expect(
        find.descendant(
          of: find.byKey(const Key('support-request-r1')),
          matching: find.text('Répondu'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('console : publier une annonce avec destinataires', (
      tester,
    ) async {
      announcements = FakeAnnouncementRepository(
        all: [announcement(id: 'old')],
      );
      await openApp(tester);
      await go(tester, AppRoutes.console);
      await openTile(tester, 'console-nav-announcements');
      expect(find.byKey(const Key('console-announcement-old')), findsOneWidget);

      await tester.tap(find.byKey(const Key('console-announcement-new')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('announcement-title')),
        'Nouveauté',
      );
      await tester.enterText(
        find.byKey(const Key('announcement-body')),
        'Le support est disponible dans le profil.',
      );
      await tester.tap(find.byKey(const Key('announcement-publish')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('announcement-audience-missing')),
        findsOneWidget,
      );
      expect(announcements.published, isNull);

      await tester.tap(find.byKey(const Key('announcement-audience-users')));
      await tester.tap(
        find.byKey(const Key('announcement-audience-promoters')),
      );
      await tester.tap(find.byKey(const Key('announcement-duration-none')));
      await tester.pump();
      final publish = find.byKey(const Key('announcement-publish'));
      await tester.ensureVisible(publish);
      await tester.tap(publish);
      await tester.pumpAndSettle();
      expect(announcements.published?.audiences, {
        AnnouncementAudience.users,
        AnnouncementAudience.promoters,
      });
      expect(announcements.published?.endsAt, isNull);
      expect(announcements.published?.important, isFalse);
      // Retour à la liste, relue.
      expect(find.byKey(const Key('console-announcement-pub-1')), findsOne);
    });

    testWidgets('console : retirer une annonce', (tester) async {
      announcements = FakeAnnouncementRepository(all: [announcement()]);
      await openApp(tester);
      await go(tester, AppRoutes.console);
      await openTile(tester, 'console-nav-announcements');
      await tester.tap(
        find.byKey(const Key('console-announcement-archive-a1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('console-announcement-archive-confirm')),
      );
      await tester.pumpAndSettle();
      expect(announcements.archived, ['a1']);
      expect(find.text('Hors ligne'), findsOneWidget);
    });
  });
}
