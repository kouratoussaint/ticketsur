import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/join_organization_page.dart';
import 'package:ticketsur/features/team/data/supabase_team_repository.dart';
import 'package:ticketsur/features/team/domain/team.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_event_setup_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_team_repository.dart';
import '../../helpers/navigation.dart';

const _me = AuthUser(id: 'u-owner', email: 'chef@exemple.bf');

TeamMember _member(
  String id,
  String name,
  MemberRole role, {
  bool active = true,
}) => TeamMember(
  userId: id,
  displayName: name,
  email: '$id@exemple.bf',
  role: role,
  active: active,
);

void main() {
  group('domaine', () {
    test('codes serveur de l’équipe', () {
      for (final (code, failure) in [
        ('org_forbidden', TeamFailure.forbidden),
        ('invitation_role_invalid', TeamFailure.invalid),
        ('member_not_found', TeamFailure.memberNotFound),
        ('member_is_owner', TeamFailure.isOwner),
        ('member_is_self', TeamFailure.isSelf),
        ('checkpoint_not_found', TeamFailure.checkpointNotFound),
        ('event_locked', TeamFailure.locked),
      ]) {
        expect(
          mapTeamError(PostgrestException(message: code, code: '22023')),
          failure,
          reason: code,
        );
      }
    });

    test('résultats de accept_invitation', () {
      expect(JoinResult.fromWire('joined'), JoinResult.joined);
      expect(JoinResult.fromWire('already_member'), JoinResult.alreadyMember);
      expect(JoinResult.fromWire('rate_limited'), JoinResult.rateLimited);
      expect(JoinResult.fromWire('???'), JoinResult.invalid);
    });

    test('mise en forme du code pendant la saisie', () {
      expect(
        InvitationCodeFormatter.format('tsi abcd efgh jkmn'),
        'TSI-ABCD-EFGH-JKMN',
      );
      // Préfixe facultatif, caractères ambigus (0, O, 1, I) écartés.
      expect(InvitationCodeFormatter.format('ab0cO1dI'), 'TSI-ABCD');
      expect(
        InvitationCodeFormatter.format('ABCDEFGHJKMNPQRS'),
        'TSI-ABCD-EFGH-JKMN',
      );
      expect(InvitationCodeFormatter.format('---'), '');
    });
  });

  group('onglet Équipe (S16)', () {
    late FakeTeamRepository team;
    late List<String> shared;

    Future<void> openTeam(
      WidgetTester tester, {
      MemberRole role = MemberRole.owner,
    }) async {
      shared = [];
      // Écran de téléphone (en-tête de la direction artistique).
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: _me),
            organizations: FakeOrganizationRepository([
              Organization(
                id: testOrganization.id,
                name: 'Nuits Sacrées',
                slug: testOrganization.slug,
                role: role,
              ),
            ]),
            team: team,
            share: (text) async => shared.add(text),
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Équipe'),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(
      () => team = FakeTeamRepository(
        members: [
          _member('u-owner', 'Awa', MemberRole.owner),
          _member('u-mgr', 'Boris', MemberRole.manager),
          _member('u-ctl', 'Clarisse', MemberRole.controller),
        ],
        invitations: [
          Invitation(
            id: 'inv-old',
            role: MemberRole.controller,
            codeHint: 'K7QP',
            expiresAt: DateTime.utc(2030, 3, 1, 10),
            maxUses: 5,
            uses: 2,
          ),
        ],
      ),
    );

    testWidgets('membres et invitations en cours', (tester) async {
      await openTeam(tester);
      expect(find.text('Awa (Vous)'), findsOneWidget);
      expect(find.text('Boris'), findsOneWidget);
      expect(find.text('Contrôleur · code …K7QP'), findsOneWidget);
      expect(find.textContaining('2 sur 5'), findsOneWidget);
    });

    testWidgets('inviter : code affiché une fois, partage prêt à envoyer', (
      tester,
    ) async {
      await openTeam(tester);
      await tester.tap(find.byKey(const Key('team-invite')));
      await tester.pumpAndSettle();
      // Le rôle « Gestionnaire » est aussi en pastille dans la liste, sous
      // la feuille : on touche celui de la feuille.
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Gestionnaire'),
        ),
      );
      await tester.tap(find.byKey(const Key('invite-days-30')));
      await tester.tap(find.byKey(const Key('invite-uses-5')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('invite-create')));
      await tester.pumpAndSettle();

      expect(team.calls, ['invite manager 30 5']);
      expect(find.text('TSI-ABCD-EFGH-WXYZ'), findsOneWidget);
      expect(
        find.text('Partagez-le maintenant : il ne sera plus jamais affiché.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('invite-share')));
      await tester.pumpAndSettle();
      expect(shared.single, contains('TSI-ABCD-EFGH-WXYZ'));
      expect(shared.single, contains('« Nuits Sacrées »'));
      expect(shared.single, contains('gestionnaire'));

      await tester.tap(find.byKey(const Key('invite-done')));
      await tester.pumpAndSettle();
      expect(find.text('Gestionnaire · code …WXYZ'), findsOneWidget);
    });

    testWidgets('gestionnaire : invite seulement des contrôleurs', (
      tester,
    ) async {
      await openTeam(tester, role: MemberRole.manager);
      await tester.tap(find.byKey(const Key('team-invite')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('invite-role')),
          matching: find.text('Gestionnaire'),
        ),
        findsNothing,
      );
    });

    testWidgets('désactiver un contrôleur (ORG-03)', (tester) async {
      await openTeam(tester);
      await tester.tap(find.byKey(const Key('member-u-ctl')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('member-active')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('member-save')));
      await tester.pumpAndSettle();
      expect(team.calls, ['update u-ctl controller false']);
      expect(find.text('Accès mis à jour'), findsOneWidget);
      expect(find.textContaining('Désactivé'), findsOneWidget);
    });

    testWidgets('refus serveur affiché dans la feuille du membre', (
      tester,
    ) async {
      await openTeam(tester);
      await tester.tap(find.byKey(const Key('member-u-mgr')));
      await tester.pumpAndSettle();
      team.nextWriteFailure = TeamFailure.forbidden;
      await tester.tap(find.byKey(const Key('member-save')));
      await tester.pumpAndSettle();
      expect(
        find.text('Action non autorisée pour votre rôle.'),
        findsOneWidget,
      );
    });

    testWidgets('propriétaire et soi-même : non modifiables', (tester) async {
      await openTeam(tester, role: MemberRole.manager);
      await tester.tap(find.byKey(const Key('member-u-owner')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('member-save')), findsNothing);
      // Un gestionnaire ne modifie pas un autre gestionnaire.
      await tester.tap(find.byKey(const Key('member-u-mgr')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('member-save')), findsNothing);
    });

    testWidgets('révoquer une invitation après confirmation', (tester) async {
      await openTeam(tester);
      await tester.tap(find.byKey(const Key('invitation-revoke-inv-old')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('team-revoke-confirm')));
      await tester.pumpAndSettle();
      expect(team.calls, ['revoke inv-old']);
      expect(find.text('Contrôleur · code …K7QP'), findsNothing);
    });
  });

  group('rejoindre avec un code', () {
    testWidgets(
      'première connexion : code accepté → espace de l’organisation',
      (tester) async {
        final orgs = FakeOrganizationRepository()
          ..nextJoin = const JoinOutcome(
            JoinResult.joined,
            Organization(
              id: 'org-x',
              name: 'Festival Invité',
              slug: 'festival-invite',
              role: MemberRole.controller,
            ),
          );
        await tester.pumpWidget(
          ProviderScope(
            overrides: await appOverrides(
              auth: FakeAuthRepository(user: _me),
              organizations: orgs,
            ),
            child: const TicketSurApp(),
          ),
        );
        await tester.pumpAndSettle();
        // Compte classique : Profil → « Rejoindre une équipe avec un code ».
        await tester.tap(find.text('Profil').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('profile-join')));
        await tester.pumpAndSettle();
        expect(find.byType(JoinOrganizationPage), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('join-code')),
          'abcd efgh jkmn',
        );
        await tester.pumpAndSettle();
        expect(find.text('TSI-ABCD-EFGH-JKMN'), findsOneWidget);
        await tester.tap(find.byKey(const Key('join-submit')));
        await tester.pumpAndSettle();
        // Écran « Code accepté » : la structure et le rôle, puis Commencer.
        expect(find.byKey(const Key('join-accepted')), findsOneWidget);
        expect(find.text('Contrôleur'), findsOneWidget);
        await tester.tap(find.byKey(const Key('join-start')));
        await tester.pumpAndSettle();

        expect(orgs.joinCalls, ['TSI-ABCD-EFGH-JKMN']);
        expect(find.byType(JoinOrganizationPage), findsNothing);
        // Contrôleur : sa barre (Contrôle…), la structure dans le profil.
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Contrôle'),
          ),
          findsOneWidget,
        );
        expect(find.text('Festival Invité'), findsWidgets);
      },
    );

    testWidgets('code refusé : message clair, on reste sur la page', (
      tester,
    ) async {
      final orgs = FakeOrganizationRepository()
        ..nextJoin = const JoinOutcome(JoinResult.expired);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: _me),
            organizations: orgs,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-join')));
      await tester.pumpAndSettle();
      // Bouton inactif tant que le code est incomplet.
      await tester.enterText(find.byKey(const Key('join-code')), 'ABCD');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TikeoPrimaryButton>(find.byKey(const Key('join-submit')))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const Key('join-code')),
        'ABCDEFGHJKMN',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('join-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text('Ce code a expiré ou a déjà servi. Demandez-en un nouveau.'),
        findsOneWidget,
      );
      expect(find.byType(JoinOrganizationPage), findsOneWidget);
    });
  });

  group('affectations (S17)', () {
    testWidgets('affecter un contrôleur à une porte, puis le retirer', (
      tester,
    ) async {
      final team = FakeTeamRepository(
        members: [
          _member('u-owner', 'Awa', MemberRole.owner),
          _member('u-ctl', 'Clarisse', MemberRole.controller),
          _member('u-off', 'Désactivé', MemberRole.controller, active: false),
        ],
      );
      final events = FakeEventRepository([
        testEvent(id: 'e1', status: EventStatus.published),
      ]);
      final setup = FakeEventSetupRepository(
        checkpoints: const [
          Checkpoint(id: 'p1', eventId: 'e1', name: 'Entrée', active: true),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(user: _me),
            events: events,
            setup: setup,
            team: team,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      // L'onglet Équipe charge les membres (utilisés par la feuille).
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Équipe'),
        ),
      );
      await tester.pumpAndSettle();
      await openEventsList(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-card-e1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('event-team-empty')), findsOneWidget);

      final add = find.byKey(const Key('assignment-add'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('assign-member')));
      await tester.pumpAndSettle();
      // Les membres désactivés ne sont pas proposés.
      expect(find.text('Désactivé · Contrôleur'), findsNothing);
      await tester.tap(find.text('Clarisse · Contrôleur').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('assign-checkpoint')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrée').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('assign-submit')));
      await tester.pumpAndSettle();

      expect(team.calls, ['assign u-ctl p1']);
      expect(
        find.descendant(
          of: find.byKey(const Key('event-team-section')),
          matching: find.text('Clarisse'),
        ),
        findsOneWidget,
      );

      final remove = find.byKey(const Key('assignment-remove-asg-1'));
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('assignment-remove-confirm')));
      await tester.pumpAndSettle();
      expect(team.calls.last, 'unassign asg-1');
      expect(find.byKey(const Key('event-team-empty')), findsOneWidget);
    });
  });
}
