import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/billing/application/billing_admin_providers.dart';
import 'package:ticketsur/features/billing/data/supabase_billing_admin_repository.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/features/billing/presentation/console_collect_pages.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_billing_admin_repository.dart';
import '../../helpers/fake_organization_repository.dart';

/// Console de facturation (C1 à C6, ADR 0027).
void main() {
  final now = DateTime.utc(2026, 11, 20, 12);

  BillingRequest request({
    String id = 'r1',
    PaymentChannel? channel = PaymentChannel.orangeMoney,
  }) => BillingRequest(
    id: id,
    accountId: 'u2',
    accountName: 'Awa Ouédraogo',
    accountEmail: 'awa@faso.bf',
    addonsOnly: false,
    packId: 'pk1',
    packName: 'Pro',
    duration: BillingDuration.quarter,
    amount: 24000,
    reference: 'TK-AB12',
    declaredChannel: channel,
    declaredTransaction: channel == null ? null : 'PP2611.1234',
    createdAt: now,
  );

  AdminSubscription subscription({
    String id = 's1',
    DateTime? endsAt,
    String? packCode,
  }) => AdminSubscription(
    id: id,
    accountId: 'u2',
    accountName: 'Awa Ouédraogo',
    accountEmail: 'awa@faso.bf',
    packId: 'pk1',
    packCode: packCode,
    packName: 'Pro',
    duration: BillingDuration.month,
    startsAt: now.subtract(const Duration(days: 20)),
    endsAt: endsAt ?? now.add(const Duration(days: 10)),
  );

  group('domaine', () {
    test('lecture de admin_billing (version 2)', () {
      final billing = AdminBilling.fromJson(const {
        'version': 2,
        'settings': {'orange_money_number': '70', 'grace_days': 5},
        'packs': [
          {
            'pack_id': 'pk1',
            'name': 'Pro',
            'system': 'flat',
            'status': 'published',
            'monthly_price': 9000,
            'durations': {'month': 9000, 'quarter': 24000},
            'options': {
              'members_per_structure': {
                'included': 3,
                'addon_price': 1000,
                'addon_step': 1,
              },
              'export': {'state': 'unavailable', 'addon_step': 1},
              'inconnue': {'included': 1},
            },
            'subscriptions': 4,
          },
        ],
        'requests': [
          {
            'id': 'r1',
            'account_id': 'u2',
            'account_name': 'Awa',
            'account_email': 'awa@faso.bf',
            'kind': 'subscription',
            'pack_id': 'pk1',
            'duration': 'quarter',
            'addons': {'members_per_structure': 2},
            'amount': 30000,
            'reference': 'TK-AB12',
            'declared_channel': 'moov_money',
            'created_at': '2026-11-20T10:00:00Z',
          },
        ],
        'invoices': [
          {
            'id': 'i1',
            'account_id': 'u2',
            'account_name': 'Awa',
            'event_id': 'e1',
            'event_title': 'Gala',
            'entries': 120,
            'amount': 18000,
            'issued_at': '2026-11-19T10:00:00Z',
            'due_at': '2026-11-18T10:00:00Z',
            'overdue': true,
          },
        ],
        'history': [
          {
            'type': 'invoice',
            'id': 'i0',
            'account_name': 'Awa',
            'event_title': 'Concert',
            'amount': 5000,
            'status': 'paid',
            'channel': 'orange_money',
          },
        ],
      });
      final pack = billing.packs.single;
      expect(pack.durations[BillingDuration.quarter], 24000);
      expect(pack.options.keys, {
        BillingOption.membersPerStructure,
        BillingOption.export,
      });
      expect(
        pack.options[BillingOption.export]!.state,
        FeatureState.unavailable,
      );
      expect(billing.settings.graceDays, 5);
      expect(billing.requests.single.declaredChannel, PaymentChannel.moovMoney);
      expect(billing.requests.single.addons, {'members_per_structure': 2});
      expect(billing.invoices.single.overdue, isTrue);
      expect(billing.history.single.invoice, isTrue);
      expect(billing.toCollect, 2);
    });

    test('pack envoyé : options par défaut omises', () {
      final json = const BillingPack(
        id: '',
        name: 'Soirée',
        system: BillingSystem.usage,
        entryPrice: 100,
        tiers: [(upTo: 500, price: 150), (upTo: null, price: 100)],
        options: {
          BillingOption.controllersPerEvent: PackOptionSetting(
            option: BillingOption.controllersPerEvent,
            included: 2,
            addonPrice: 1000,
          ),
        },
      ).toSaveJson();
      expect(json['system'], 'usage');
      expect(json['monthly_price'], isNull);
      expect(json['durations'], isEmpty);
      expect(json['tiers'], [
        {'up_to': 500, 'price': 150},
        {'up_to': null, 'price': 100},
      ]);
      expect(json['options'], [
        {
          'key': 'controllers_per_event',
          'included': 2,
          'addon_price': 1000,
          'addon_step': 1,
          'addon_cap': null,
        },
      ]);
    });

    test('début d’un renouvellement : fin de l’abonnement payant en cours', () {
      final billing = AdminBilling(
        settings: const BillingSettings(),
        subscriptions: [
          subscription(),
          subscription(
            id: 's2',
            packCode: 'lancement',
            endsAt: now.add(const Duration(days: 60)),
          ),
        ],
      );
      expect(
        subscriptionStart(billing, 'u2', now),
        now.add(const Duration(days: 10)),
      );
      expect(subscriptionStart(billing, 'u3', now), now);
      expect(
        BillingDuration.quarter.endFrom(DateTime.utc(2026, 11, 30)),
        DateTime.utc(2027, 2, 30),
      );
    });

    test('états d’un abonnement', () {
      expect(
        subscription(endsAt: now.add(const Duration(days: 3)))
            .stateAt(now, graceDays: 7),
        SubscriptionState.endingSoon,
      );
      expect(
        subscription(endsAt: now.subtract(const Duration(days: 3)))
            .stateAt(now, graceDays: 7),
        SubscriptionState.grace,
      );
      expect(
        subscription(endsAt: now.subtract(const Duration(days: 9)))
            .stateAt(now, graceDays: 7),
        SubscriptionState.ended,
      );
    });

    test('erreurs serveur traduites', () {
      supabase.PostgrestException error(String message, [String? code]) =>
          supabase.PostgrestException(message: message, code: code);
      expect(
        mapBillingAdminError(error('forbidden')),
        BillingAdminFailure.forbidden,
      );
      expect(
        mapBillingAdminError(error('billing_note_required')),
        BillingAdminFailure.noteRequired,
      );
      expect(
        mapBillingAdminError(error('billing_invoice_exists')),
        BillingAdminFailure.invoiceExists,
      );
      expect(
        mapBillingAdminError(error('billing_request_not_found')),
        BillingAdminFailure.alreadyProcessed,
      );
      expect(mapBillingAdminError(error('autre')), BillingAdminFailure.unknown);
    });
  });

  group('écrans', () {
    late FakeBillingAdminRepository billing;
    late FakeAdminRepository admin;

    setUp(() {
      admin = FakeAdminRepository(admin: true);
      billing = FakeBillingAdminRepository(
        billing: AdminBilling(
          settings: const BillingSettings(orangeMoneyNumber: '70 00 00 00'),
          packs: [
            testPack(code: 'decouverte', id: 'free', name: 'Découverte'),
            testPack(
              options: {
                BillingOption.membersPerStructure: const PackOptionSetting(
                  option: BillingOption.membersPerStructure,
                  included: 2,
                  addonPrice: 1000,
                ),
              },
            ),
            testPack(id: 'pk2', name: 'Business', status: PackStatus.draft),
            testPack(id: 'pu', name: 'Soirée', system: BillingSystem.usage),
          ],
          requests: [request()],
          subscriptions: [subscription()],
          invoices: [
            DueInvoice(
              id: 'i1',
              accountId: 'u2',
              accountName: 'Awa Ouédraogo',
              eventId: 'e1',
              eventTitle: 'Gala',
              entries: 120,
              amount: 18000,
              issuedAt: now,
              dueAt: now.subtract(const Duration(days: 1)),
              overdue: true,
            ),
          ],
        ),
        eventRows: [
          BillingEventRow(
            id: 'e1',
            title: 'Gala',
            organizationName: 'Kwabo',
            system: BillingSystem.flat,
            locked: true,
            startsAt: now,
          ),
        ],
      );
    });

    Future<void> openAt(WidgetTester tester, String path) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...await appOverrides(
              auth: FakeAuthRepository(
                user: const AuthUser(id: 'u1', email: 'admin@tikeo.bf'),
              ),
              organizations: FakeOrganizationRepository([testOrganization]),
              admin: admin,
              billingAdmin: billing,
            ),
            billingClockProvider.overrideWithValue(() => now),
          ],
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
      await tester.pumpAndSettle();
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      // Un champ qui garde le focus ramène la liste vers lui.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('console : section Facturation et paiements à vérifier', (
      tester,
    ) async {
      await openAt(tester, AppRoutes.console);
      final collect = find.byKey(const Key('console-nav-collect'));
      await tester.ensureVisible(collect);
      expect(
        find.descendant(
          of: collect,
          matching: find.text('2 paiements à vérifier'),
        ),
        findsOneWidget,
      );
      await tapVisible(tester, collect);
      expect(find.byKey(const Key('billing-request-r1')), findsOneWidget);
    });

    testWidgets('C1 : filtres, publier un brouillon, dupliquer', (
      tester,
    ) async {
      await openAt(tester, AppRoutes.consolePacks);
      expect(find.byKey(const Key('billing-pack-pk2')), findsOneWidget);
      await tester.tap(find.byKey(const Key('billing-packs-usage')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('billing-pack-pk2')), findsNothing);
      expect(find.byKey(const Key('billing-pack-pu')), findsOneWidget);
      await tester.tap(find.byKey(const Key('billing-packs-all')));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('billing-pack-menu-pk2')));
      await tester.tap(find.byKey(const Key('billing-pack-publish-pk2')));
      await tester.pumpAndSettle();
      expect(billing.calls, contains('status pk2 published'));

      await tapVisible(tester, find.byKey(const Key('billing-pack-menu-pk1')));
      await tester.tap(find.byKey(const Key('billing-pack-duplicate-pk1')));
      await tester.pumpAndSettle();
      expect(billing.savedPacks.single.name, 'Pro (copie)');
      expect(
        billing
            .savedPacks
            .single
            .options[BillingOption.membersPerStructure]
            ?.addonPrice,
        1000,
      );
    });

    testWidgets('C2 : créer un pack à l’usage avec paliers et le publier', (
      tester,
    ) async {
      await openAt(tester, AppRoutes.consolePackNew);
      await tester.tap(find.byKey(const Key('billing-form-system-usage')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('billing-form-name')),
        'Soirée+',
      );
      await tester.enterText(
        find.byKey(const Key('billing-form-entry')),
        '100',
      );
      await tapVisible(tester, find.byKey(const Key('billing-form-tier-add')));
      await tester.enterText(
        find.byKey(const Key('billing-form-tier-upto-0')),
        '500',
      );
      await tester.enterText(
        find.byKey(const Key('billing-form-tier-price-0')),
        '150',
      );
      // Contrôleurs : 2 inclus, supplément à 1 000 FCFA.
      await tester.ensureVisible(
        find.byKey(
          const Key('billing-form-option-controllers_per_event-included'),
        ),
      );
      await tester.enterText(
        find.byKey(
          const Key('billing-form-option-controllers_per_event-included'),
        ),
        '2',
      );
      await tapVisible(
        tester,
        find.byKey(
          const Key('billing-form-option-controllers_per_event-addon'),
        ),
      );
      await tester.enterText(
        find.byKey(
          const Key('billing-form-option-controllers_per_event-price'),
        ),
        '1000',
      );
      // Export indisponible.
      await tapVisible(
        tester,
        find.byKey(const Key('billing-form-feature-export-unavailable')),
      );
      await tapVisible(tester, find.byKey(const Key('billing-form-publish')));

      final pack = billing.savedPacks.single;
      expect(pack.system, BillingSystem.usage);
      expect(pack.entryPrice, 100);
      expect(pack.tiers, [(upTo: 500, price: 150)]);
      final json = pack.toSaveJson()['options']! as List;
      expect(json, hasLength(2));
      expect(pack.options[BillingOption.controllersPerEvent]!.addonPrice, 1000);
      expect(
        pack.options[BillingOption.export]!.state,
        FeatureState.unavailable,
      );
      expect(billing.calls, contains('status new-1 published'));
    });

    testWidgets('C2 : nom trop court refusé, rien n’est envoyé', (
      tester,
    ) async {
      await openAt(tester, AppRoutes.consolePackNew);
      await tester.enterText(find.byKey(const Key('billing-form-name')), 'A');
      await tapVisible(tester, find.byKey(const Key('billing-form-save')));
      expect(find.byKey(const Key('billing-form-error')), findsOneWidget);
      expect(billing.savedPacks, isEmpty);
    });

    testWidgets('C3 et C4 : valider une demande payée par Moov', (
      tester,
    ) async {
      await openAt(tester, AppRoutes.consoleCollect);
      expect(find.byKey(const Key('billing-invoice-i1')), findsNothing);
      await tapVisible(
        tester,
        find.byKey(const Key('billing-request-check-r1')),
      );
      // Dates : l'abonnement en cours finit dans 10 jours.
      expect(find.textContaining('Du 30 nov. 2026'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('billing-payment-reference')),
            )
            .controller!
            .text,
        'PP2611.1234',
      );
      await tester.tap(
        find.byKey(const Key('billing-payment-channel-moov_money')),
      );
      await tester.enterText(
        find.byKey(const Key('billing-payment-amount')),
        '20000',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('billing-payment-mismatch')), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const Key('billing-payment-validate')),
      );
      expect(billing.calls, contains('activate r1'));
      expect(billing.lastPayment!.channel, PaymentChannel.moovMoney);
      expect(billing.lastPayment!.note, contains('Reçu'));
    });

    testWidgets('C3 : facture en retard, marquée payée', (tester) async {
      await openAt(tester, AppRoutes.consoleCollect);
      await tester.tap(find.byKey(const Key('billing-collect-overdue')));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const Key('billing-invoice-check-i1')),
      );
      expect(find.byKey(const Key('billing-payment-refuse')), findsNothing);
      await tapVisible(
        tester,
        find.byKey(const Key('billing-payment-validate')),
      );
      expect(billing.calls, contains('paid i1'));
    });

    testWidgets('C4 : refuser une demande avec un motif', (tester) async {
      await openAt(tester, AppRoutes.consoleCollectRequest('r1'));
      await tapVisible(tester, find.byKey(const Key('billing-payment-refuse')));
      await tester.enterText(
        find.byKey(const Key('console-reason')),
        'Paiement introuvable',
      );
      await tester.tap(find.byKey(const Key('billing-refuse-confirm')));
      await tester.pumpAndSettle();
      expect(billing.calls, contains('refuse r1'));
      expect(billing.lastNote, 'Paiement introuvable');
    });

    testWidgets('C5 : tuiles, prolonger, changer de pack', (tester) async {
      await openAt(tester, AppRoutes.consoleSubscriptions);
      expect(
        find.descendant(
          of: find.byKey(const Key('billing-sub-tile-active')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const Key('billing-sub-menu-s1')));
      await tester.tap(find.byKey(const Key('billing-sub-extend-s1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('console-reason')),
        'Geste commercial',
      );
      await tester.tap(find.byKey(const Key('billing-note-confirm')));
      await tester.pumpAndSettle();
      expect(billing.calls, contains('extend s1'));

      await tapVisible(tester, find.byKey(const Key('billing-sub-menu-s1')));
      await tester.tap(find.byKey(const Key('billing-sub-pack-s1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('billing-pick-pk2')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('console-reason')),
        'Montée en gamme',
      );
      await tester.tap(find.byKey(const Key('billing-note-confirm')));
      await tester.pumpAndSettle();
      expect(billing.calls, contains('pack s1 pk2'));
    });

    testWidgets('C5 : suppléments d’un abonnement', (tester) async {
      await openAt(tester, AppRoutes.consoleSubscriptions);
      await tapVisible(tester, find.byKey(const Key('billing-sub-menu-s1')));
      await tester.tap(find.byKey(const Key('billing-sub-addons-s1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey("[<'billing-addon-members_per_structure'>]-plus"),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('billing-addons-next')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('console-reason')),
        'Équipe plus grande',
      );
      await tester.tap(find.byKey(const Key('billing-note-confirm')));
      await tester.pumpAndSettle();
      expect(billing.calls, contains('addons s1 {members_per_structure: 1}'));
    });

    testWidgets('C5 : activer un pack sans demande', (tester) async {
      await openAt(tester, AppRoutes.consoleSubscriptions);
      await tapVisible(tester, find.byKey(const Key('billing-grant')));
      await tester.tap(find.byKey(const Key('billing-grant-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text('Choisissez le compte et le pack, et indiquez le motif.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('billing-grant-search')),
          matching: find.byType(TextField),
        ),
        'Awa',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('billing-grant-account-u2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('billing-grant-pack-pk1')));
      await tester.tap(find.byKey(const Key('billing-grant-duration-quarter')));
      await tester.enterText(
        find.byKey(const Key('billing-grant-note')),
        'Partenaire',
      );
      await tapVisible(tester, find.byKey(const Key('billing-grant-submit')));
      expect(billing.calls, contains('grant u2 pk1 quarter'));
      expect(billing.lastNote, 'Partenaire');
    });

    testWidgets('C5 : passer un événement figé à l’usage', (tester) async {
      await openAt(tester, AppRoutes.consoleSubscriptions);
      await tapVisible(tester, find.byKey(const Key('billing-event-change')));
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('billing-event-search')),
          matching: find.byType(TextField),
        ),
        'Gala',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('billing-event-e1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('billing-event-system-usage')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('billing-event-pack-pu')));
      await tester.enterText(
        find.byKey(const Key('billing-event-note')),
        'Erreur de choix',
      );
      await tapVisible(tester, find.byKey(const Key('billing-event-submit')));
      expect(billing.calls, contains('event e1 usage pu'));
    });

    testWidgets('C6 : réglages de paiement enregistrés', (tester) async {
      await openAt(tester, AppRoutes.consolePaymentSettings);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('billing-settings-orange')))
            .controller!
            .text,
        '70 00 00 00',
      );
      await tester.enterText(
        find.byKey(const Key('billing-settings-moov')),
        '60 11 22 33',
      );
      await tester.enterText(
        find.byKey(const Key('billing-settings-grace-days')),
        '10',
      );
      await tapVisible(tester, find.byKey(const Key('billing-settings-save')));
      expect(billing.savedSettings!.moovMoneyNumber, '60 11 22 33');
      expect(billing.savedSettings!.graceDays, 10);
      expect(billing.savedSettings!.usagePaymentDays, 7);
    });

    testWidgets(
      "C6 : erreur inattendue à l'enregistrement, message lisible (#21)",
      (tester) async {
        await openAt(tester, AppRoutes.consolePaymentSettings);
        billing.nextFailure = BillingAdminFailure.unknown;
        await tapVisible(
          tester,
          find.byKey(const Key('billing-settings-save')),
        );
        expect(find.byKey(const Key('billing-settings-error')), findsOneWidget);
        expect(
          find.textContaining('Enregistrement impossible'),
          findsOneWidget,
        );
      },
    );

    testWidgets('échec du serveur : message, rien ne plante', (tester) async {
      billing.nextFailure = BillingAdminFailure.forbidden;
      await openAt(tester, AppRoutes.consolePacks);
      expect(find.byKey(const Key('billing-error')), findsOneWidget);
    });
  });
}
