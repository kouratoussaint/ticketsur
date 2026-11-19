import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/events/application/cover_picker.dart';
import 'package:ticketsur/features/events/domain/event.dart' show CoverImage;
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/profile/domain/profile.dart';
import 'package:ticketsur/features/profile/presentation/edit_profile_page.dart';
import 'package:ticketsur/features/profile/profile_page.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_organization_repository.dart';
import '../../helpers/fake_profile_repository.dart';

/// PNG 1×1 valide.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB'
  '0C8AAAAASUVORK5CYII=',
);

void main() {
  group('domaine', () {
    test('initiales, date de suppression, validations', () {
      final profile = UserProfile.fromJson(const {
        'id': 'u1',
        'display_name': 'awa  ouédraogo',
        'deletion_requested_at': '2030-01-01T00:00:00Z',
      });
      expect(profile.initials, 'AO');
      expect(profile.deletionDueAt, DateTime.utc(2030, 1, 31));
      expect(isValidDisplayName(' A '), isFalse);
      expect(isValidDisplayName('Awa'), isTrue);
      expect(isValidPhone(''), isTrue);
      expect(isValidPhone('70 12 34 56'), isTrue);
      expect(isValidPhone('+225 07 00 00 00 00'), isTrue);
      expect(isValidPhone('00226 70123456'), isTrue);
      expect(isValidPhone('123'), isFalse);
      expect(isValidPhone('70-12-AB'), isFalse);
      expect(formatPhone('+22670123456'), '+226 70 12 34 56');
      expect(formatPhone('+2250700000000'), '+2250700000000');
    });

    test('codes serveur', () {
      expect(
        ProfileFailure.fromServerCode('profile_phone_invalid'),
        ProfileFailure.phoneInvalid,
      );
      expect(ProfileFailure.fromServerCode('autre'), ProfileFailure.unknown);
    });
  });

  group('profil (S28)', () {
    late FakeAuthRepository auth;
    late FakeProfileRepository profile;
    late FakeOrganizationRepository organizations;
    late List<CoverSource> squareCalls;

    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: auth,
            profile: profile,
            organizations: organizations,
            squarePicker: (source) async {
              squareCalls.add(source);
              return CoverImage(bytes: _png, mimeType: 'image/png');
            },
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Profil'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    setUp(() {
      auth = FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'awa@exemple.bf'),
      );
      profile = FakeProfileRepository(
        const UserProfile(
          id: 'u1',
          displayName: 'Awa Ouédraogo',
          phone: '+22670123456',
        ),
      );
      organizations = FakeOrganizationRepository([testOrganization]);
      squareCalls = [];
    });

    testWidgets('identité affichée : nom, adresse, téléphone', (tester) async {
      await pumpApp(tester);
      expect(find.text('Awa Ouédraogo'), findsOneWidget);
      expect(find.text('awa@exemple.bf'), findsOneWidget);
      expect(find.text('+226 70 12 34 56'), findsOneWidget);
    });

    testWidgets('modifier nom et téléphone', (tester) async {
      await pumpApp(tester);
      await tapVisible(tester, find.byKey(const Key('profile-edit')));
      expect(find.byType(EditProfilePage), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('profile-name-field')),
        ' Awa  Kaboré ',
      );
      await tester.enterText(
        find.byKey(const Key('profile-phone-field')),
        '76 00 00 01',
      );
      await tapVisible(tester, find.byKey(const Key('profile-save')));
      expect(profile.updateCalls.single.name, ' Awa  Kaboré ');
      expect(find.byType(EditProfilePage), findsNothing);
      expect(find.text('Awa Kaboré'), findsOneWidget);
      expect(find.text('+226 76 00 00 01'), findsOneWidget);
      expect(find.text('Profil enregistré'), findsOneWidget);
    });

    testWidgets('téléphone invalide : refus local', (tester) async {
      await pumpApp(tester);
      await tapVisible(tester, find.byKey(const Key('profile-edit')));
      await tester.enterText(
        find.byKey(const Key('profile-phone-field')),
        '123',
      );
      await tapVisible(tester, find.byKey(const Key('profile-save')));
      expect(find.text('Numéro de téléphone invalide.'), findsOneWidget);
      expect(profile.updateCalls, isEmpty);
    });

    testWidgets('changer la photo de profil', (tester) async {
      await pumpApp(tester);
      await tapVisible(tester, find.byKey(const Key('profile-edit')));
      await tapVisible(tester, find.byKey(const Key('profile-photo-change')));
      await tester.tap(find.byKey(const Key('cover-source-gallery')));
      await tester.pumpAndSettle();
      expect(squareCalls, [CoverSource.gallery]);
      expect(profile.avatarCalls, hasLength(1));
      expect(find.text('Photo de profil enregistrée'), findsOneWidget);
    });

    testWidgets('mot de passe : actuel faux, puis changement réussi', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapVisible(
        tester,
        find.byKey(const Key('profile-change-password')),
      );
      await tester.enterText(find.byKey(const Key('password-current')), 'x');
      await tester.enterText(
        find.byKey(const Key('password-new')),
        'nouveau-123',
      );
      await tester.enterText(
        find.byKey(const Key('password-confirm')),
        'autre-1234',
      );
      await tapVisible(tester, find.byKey(const Key('password-submit')));
      expect(find.text('Les deux mots de passe diffèrent.'), findsOneWidget);
      expect(auth.passwordCalls, isEmpty);

      await tester.enterText(
        find.byKey(const Key('password-confirm')),
        'nouveau-123',
      );
      auth.nextAccountFailure = AuthFailure.invalidCredentials;
      await tapVisible(tester, find.byKey(const Key('password-submit')));
      expect(find.text('Mot de passe actuel incorrect.'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('password-submit')));
      expect(auth.passwordCalls, hasLength(2));
      expect(auth.passwordCalls.last.next, 'nouveau-123');
      expect(find.byKey(const Key('password-submit')), findsNothing);
      expect(find.text('Mot de passe changé'), findsOneWidget);
    });

    testWidgets('adresse e-mail : identique refusée, nouvelle envoyée', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapVisible(tester, find.byKey(const Key('profile-change-email')));
      await tester.enterText(
        find.byKey(const Key('email-new')),
        'AWA@exemple.bf',
      );
      await tapVisible(tester, find.byKey(const Key('email-submit')));
      expect(find.text("C'est déjà votre adresse."), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('email-new')),
        'awa@nouveau.bf',
      );
      await tapVisible(tester, find.byKey(const Key('email-submit')));
      expect(auth.emailCalls, ['awa@nouveau.bf']);
      expect(
        find.text('Lien de confirmation envoyé à awa@nouveau.bf.'),
        findsOneWidget,
      );
    });

    testWidgets('déconnecter tous les appareils après confirmation', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapVisible(
        tester,
        find.byKey(const Key('profile-sign-out-everywhere')),
      );
      await tester.tap(find.byKey(const Key('sign-out-everywhere-confirm')));
      await tester.pumpAndSettle();
      expect(auth.signOutEverywhereCalls, 1);
      expect(find.byType(ProfilePage), findsNothing);
    });

    testWidgets(
      'suppression du compte : mot de confirmation, puis annulation',
      (tester) async {
        await pumpApp(tester);
        await tapVisible(
          tester,
          find.byKey(const Key('profile-delete-account')),
        );
        final confirm = find.byKey(const Key('delete-confirm'));
        expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
        await tester.enterText(
          find.byKey(const Key('delete-word')),
          'supprimer',
        );
        await tester.pump();
        expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(profile.deletionCalls, [true]);
        expect(
          find.byKey(const Key('profile-deletion-pending')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('profile-delete-account')), findsNothing);

        await tapVisible(
          tester,
          find.byKey(const Key('profile-deletion-cancel')),
        );
        expect(profile.deletionCalls, [true, false]);
        expect(find.byKey(const Key('profile-deletion-pending')), findsNothing);
      },
    );

    testWidgets('propriétaire : fiche et logo de l’organisation', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapVisible(tester, find.byKey(const Key('profile-edit-org')));
      await tester.enterText(
        find.byKey(const Key('org-email-field')),
        'pas-un-mail',
      );
      await tapVisible(tester, find.byKey(const Key('org-save')));
      expect(find.text('Adresse e-mail invalide.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('org-email-field')),
        'contact@studio.bf',
      );
      await tester.enterText(
        find.byKey(const Key('org-city-field')),
        'Koudougou',
      );
      await tapVisible(tester, find.byKey(const Key('org-logo-change')));
      await tester.tap(find.byKey(const Key('cover-source-camera')));
      await tester.pumpAndSettle();
      expect(organizations.logoCalls, hasLength(1));
      await tapVisible(tester, find.byKey(const Key('org-save')));
      final draft = organizations.updateCalls.single.$2;
      expect(draft.contactEmail, 'contact@studio.bf');
      expect(draft.city, 'Koudougou');
      expect(find.text('Fiche enregistrée'), findsOneWidget);
      expect(find.textContaining('Koudougou'), findsOneWidget);
    });

    testWidgets('gestionnaire : pas de modification de la fiche', (
      tester,
    ) async {
      organizations = FakeOrganizationRepository([
        testOrganization.withRole(MemberRole.manager),
      ]);
      await pumpApp(tester);
      expect(find.byKey(const Key('profile-edit-org')), findsNothing);
      expect(find.byKey(const Key('profile-leave-org')), findsOneWidget);
    });

    testWidgets('quitter : dernier propriétaire refusé avec explication', (
      tester,
    ) async {
      await pumpApp(tester);
      organizations.nextWriteFailure = OrganizationFailure.lastOwner;
      await tapVisible(tester, find.byKey(const Key('profile-leave-org')));
      await tester.tap(find.byKey(const Key('org-leave-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('dernier propriétaire'), findsOneWidget);
      expect(find.byKey(const Key('profile-org')), findsOneWidget);
    });

    testWidgets('quitter : l’autre organisation devient active', (
      tester,
    ) async {
      organizations = FakeOrganizationRepository([
        testOrganization.withRole(MemberRole.controller),
        const Organization(
          id: 'org-2',
          name: 'Deuxième maison',
          slug: 'deuxieme',
          role: MemberRole.owner,
        ),
      ]);
      await pumpApp(tester);
      await tapVisible(tester, find.byKey(const Key('profile-leave-org')));
      await tester.tap(find.byKey(const Key('org-leave-confirm')));
      await tester.pumpAndSettle();
      expect(organizations.leaveCalls, ['org-test']);
      expect(find.text('Deuxième maison'), findsWidgets);
    });

    testWidgets('profil injoignable : message et « Réessayer »', (
      tester,
    ) async {
      profile.nextFailure = ProfileFailure.network;
      await pumpApp(tester);
      expect(find.text('Impossible de charger votre profil.'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('profile-retry')));
      expect(find.text('Awa Ouédraogo'), findsOneWidget);
    });
  });
}
