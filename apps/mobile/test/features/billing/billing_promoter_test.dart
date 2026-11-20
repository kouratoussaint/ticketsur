import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_billing_repository.dart';
import '../../helpers/fake_organization_repository.dart';

/// Parcours d'achat du promoteur (P1 à P6, ADR 0027).
void main() {
  group('domaine', () {
    test('lecture de my_billing', () {
      final billing = MyBilling.fromJson(const {
        'plan': {
          'snapshot': {
            'pack_id': 'pk1',
            'name': 'Pro',
            'system': 'flat',
            'status': 'published',
            'durations': {'month': 9000},
            'options': <String, Object?>{},
          },
          'subscription_id': 's1',
          'duration': 'month',
          'addons': {'members_per_structure': 2},
          'period_start': '2026-11-01T00:00:00Z',
          'period_end': '2026-12-01T00:00:00Z',
          'grace': false,
        },
        'limits': {'members_per_structure': 5, 'inconnue': 3},
        'features': {'export': true},
        'usage': {'structures': 1, 'active_events': 2},
        'organizations': [
          {'id': 'o1', 'name': 'Kwabo', 'billing_default': 'usage'},
        ],
        'requests': [
          {
            'id': 'r1',
            'kind': 'pack',
            'pack_id': 'pk1',
            'duration': 'month',
            'amount': 9000,
            'reference': 'TK-AB12',
            'status': 'pending',
            'declared_channel': 'orange_money',
            'created_at': '2026-11-20T10:00:00Z',
          },
        ],
        'payment': {'orange_money_number': '70'},
      });
      expect(billing.plan.pack.name, 'Pro');
      expect(billing.plan.isPaid, isTrue);
      expect(billing.plan.addons, {'members_per_structure': 2});
      expect(billing.limits, {BillingOption.membersPerStructure: 5});
      expect(billing.features[BillingOption.export], isTrue);
      expect(billing.usage.activeEvents, 2);
      expect(billing.organizations.single.system, BillingSystem.usage);
      expect(billing.pending?.declared, isTrue);
      expect(billing.requestById('r1')?.reference, 'TK-AB12');
      expect(billing.payment.orangeMoneyNumber, '70');
    });

    test("estimation à l'usage : entrées offertes puis paliers", () {
      const pack = BillingPack(
        id: 'pu',
        name: 'Soirée',
        system: BillingSystem.usage,
        status: PackStatus.published,
        entryPrice: 150,
        freeEntries: 50,
        tiers: [(upTo: null, price: 100), (upTo: 500, price: 150)],
      );
      expect(usageEstimate(pack, 40).amount, 0);
      final estimate = usageEstimate(pack, 650);
      expect(estimate.billable, 600);
      expect(estimate.amount, 500 * 150 + 100 * 100);
      expect(estimate.tiers.last, (from: 501, to: 600, price: 100));
    });
  });

  group('écrans', () {
    late FakeBillingRepository billing;

    setUp(() => billing = FakeBillingRepository());

    Future<void> openAt(WidgetTester tester, String path) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: await appOverrides(
            auth: FakeAuthRepository(
              user: const AuthUser(id: 'u1', email: 'awa@faso.bf'),
            ),
            organizations: FakeOrganizationRepository([testOrganization]),
            billing: billing,
          ),
          child: const TicketSurApp(),
        ),
      );
      await tester.pumpAndSettle();
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

    testWidgets('le Profil ouvre Mon pack', (tester) async {
      await openAt(tester, AppRoutes.profile);
      await tapVisible(tester, find.byKey(const Key('profile-billing')));
      expect(find.byKey(const Key('billing-plan-name')), findsOneWidget);
      expect(find.text('Découverte'), findsWidgets);
    });

    testWidgets("choix d'un pack, suppléments, paiement, attente", (
      tester,
    ) async {
      await openAt(tester, AppRoutes.billing);
      await tapVisible(tester, find.byKey(const Key('billing-change-pack')));
      await tapVisible(
        tester,
        find.byKey(const Key('billing-duration-quarter')),
      );
      await tapVisible(
        tester,
        find.byKey(const Key('billing-choose-pack-pk1')),
      );

      // P4 : un membre de plus, l'export en supplément, le direct grisé.
      expect(find.byKey(const Key('billing-addons-page')), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const Key('billing-addon-members_per_structure-plus')),
      );
      expect(find.text('+1'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('billing-addon-export')));
      expect(find.textContaining('Business'), findsWidgets);
      await tapVisible(
        tester,
        find.byKey(const Key('billing-addons-continue')),
      );
      expect(billing.calls, contains('request pk1 quarter'));
      expect(billing.lastAddons, {'members_per_structure': 1, 'export': 1});

      // P5 : référence, numéros, déclaration.
      expect(find.byKey(const Key('billing-pay-reference')), findsOneWidget);
      expect(find.text('TK-AB12'), findsOneWidget);
      expect(find.text('70 00 00 00'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const Key('billing-pay-channel-moov_money')),
      );
      await tester.enterText(
        find.byKey(const Key('billing-pay-transaction')),
        'MP2611.0001',
      );
      await tapVisible(tester, find.byKey(const Key('billing-pay-done')));
      expect(billing.calls, contains('declare rq1 moov_money'));
      expect(billing.lastTransaction, 'MP2611.0001');

      // P6 : en attente.
      expect(find.byKey(const Key('billing-request-pending')), findsOneWidget);
      expect(find.byKey(const Key('billing-request-steps')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('billing-request-back')));
      expect(find.byKey(const Key('billing-pending')), findsOneWidget);
    });

    testWidgets('une erreur serveur reste sur la page de paiement', (
      tester,
    ) async {
      await billing.requestPack('pk1', BillingDuration.month, const {});
      await openAt(tester, AppRoutes.billingRequest('rq1'));
      billing.nextFailure = BillingFailure.paymentInvalid;
      await tapVisible(tester, find.byKey(const Key('billing-pay-done')));
      expect(find.byKey(const Key('billing-pay-error')), findsOneWidget);
      expect(find.byKey(const Key('billing-pay-done')), findsOneWidget);
    });

    testWidgets('annuler une demande', (tester) async {
      await billing.requestPack('pk1', BillingDuration.month, const {});
      await openAt(tester, AppRoutes.billingRequest('rq1'));
      await tapVisible(tester, find.byKey(const Key('billing-pay-cancel')));
      expect(billing.calls, contains('cancel rq1'));
    });

    testWidgets("pack à l'usage : simulateur et choix pour la structure", (
      tester,
    ) async {
      await openAt(tester, AppRoutes.billingPacks);
      await tapVisible(tester, find.byKey(const Key('billing-choose-usage')));
      expect(find.byKey(const Key('billing-simulator')), findsOneWidget);
      expect(find.byKey(const Key('billing-simulator-total')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('billing-use-pu')));
      expect(billing.calls, contains('org o1 usage pu'));
    });
  });
}
