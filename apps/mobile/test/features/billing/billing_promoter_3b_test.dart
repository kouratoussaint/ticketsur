import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/app/app.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';
import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_block.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/features/billing/presentation/invoices_page.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/notifications/domain/push.dart';
import 'package:ticketsur/features/ticket_import/presentation/ticket_import_page.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/l10n/gen/app_localizations_fr.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_billing_repository.dart';
import '../../helpers/fake_event_repository.dart';
import '../../helpers/fake_organization_repository.dart';

/// Facturation côté promoteur, suite (P7, P8, P9, essai ; ADR 0027).
void main() {
  tearDown(() {
    billingBlocks.value = null;
    lastBillingBlockAt = null;
  });

  group('domaine', () {
    test("blocage du pack lu depuis l'erreur du serveur", () {
      final block = BillingBlock.fromError(
        const supabase.PostgrestException(
          message: 'billing_limit_controllers_per_event',
          code: '54000',
          hint: '{"limit": 1, "system": "usage", "event": "e1"}',
        ),
      );
      expect(block?.kind, BillingBlockKind.limit);
      expect(block?.option, BillingOption.controllersPerEvent);
      expect(block?.limit, 1);
      expect(block?.system, BillingSystem.usage);
      expect(block?.eventId, 'e1');

      final old = BillingBlock.fromError(
        const supabase.PostgrestException(
          message: 'billing_limit_structures',
          hint: '3',
        ),
      );
      expect(old?.limit, 3);
      expect(old?.system, BillingSystem.flat);

      expect(
        BillingBlock.fromError(
          const supabase.PostgrestException(message: 'billing_option_export'),
        )?.option,
        BillingOption.export,
      );
      expect(
        BillingBlock.fromError(
          const supabase.PostgrestException(message: 'billing_overdue'),
        )?.kind,
        BillingBlockKind.overdue,
      );
      expect(
        BillingBlock.fromError(
          const supabase.PostgrestException(message: 'ticket_not_found'),
        ),
        isNull,
      );
      expect(captureBillingBlock(StateError('x')), isFalse);
      expect(billingBlockJustReported, isFalse);
    });

    test("facturation d'un événement et my_billing v2", () {
      final billing = EventBilling.fromJson(const {
        'mode': 'usage',
        'system': 'usage',
        'usage_pack_id': 'pu',
        'locked': true,
        'pack_name': 'Soirée',
        'addons': {'controllers_per_event': 1},
        'limits': {'controllers_per_event': 2, 'structures': null},
        'features': {'bulk_send': false, 'export': true},
        'estimate': {
          'entries': 12,
          'free_entries': 2,
          'billable_entries': 10,
          'entries_amount': 1500,
          'addons_amount': 1000,
          'amount': 2500,
        },
        'invoice': {
          'id': 'i1',
          'amount': 2500,
          'status': 'due',
          'due_at': '2030-06-10T00:00:00Z',
        },
      });
      expect(billing.mode, EventBillingMode.usage);
      expect(billing.locked, isTrue);
      expect(billing.addons, {BillingOption.controllersPerEvent: 1});
      expect(billing.allows(BillingOption.bulkSend), isFalse);
      expect(billing.allows(BillingOption.import), isTrue);
      expect(billing.estimate?.amount, 2500);
      expect(billing.invoice?.paid, isFalse);

      final invoice = MyInvoice.fromJson(const {
        'id': 'abcdef12-0000-0000-0000-000000000000',
        'event_id': 'e1',
        'event_title': 'Gala',
        'entries': 12,
        'free_entries': 2,
        'billable_entries': 10,
        'addons_amount': 1000,
        'pack_name': 'Soirée',
        'amount': 2500,
        'status': 'due',
        'issued_at': '2030-06-01T00:00:00Z',
        'due_at': '2030-06-10T00:00:00Z',
      });
      expect(invoice.reference, 'F-ABCDEF');
      expect(invoice.billableEntries, 10);
      expect(invoice.packName, 'Soirée');
      expect(BillingDuration.fromWire('trial'), BillingDuration.trial);
    });

    test('lignes de facture et PDF', () async {
      await initializeDateFormatting('fr');
      final l10n = AppLocalizationsFr();
      final rows = invoiceRows(l10n, sampleInvoice());
      expect(rows, hasLength(3));
      expect(rows.first.$1, startsWith('Entrées 1 à 500'));
      expect(rows.last.$1, contains('Contrôleurs'));
      final pdf = await buildInvoicePdf(l10n, invoice: sampleInvoice());
      expect(String.fromCharCodes(pdf.take(4)), '%PDF');
    });

    test('notifications de facturation : routes permises', () {
      expect(isSafePushRoute('/facturation'), isTrue);
      expect(
        isSafePushRoute(
          '/facturation/factures/aaaaaaaa-0000-0000-0000-00000000f001',
        ),
        isTrue,
      );
      expect(
        isSafePushRoute(
          '/facturation/demande/aaaaaaaa-0000-0000-0000-00000000f001',
        ),
        isTrue,
      );
      expect(isSafePushRoute('/facturation/autre'), isFalse);
    });
  });

  group('écrans', () {
    late FakeBillingRepository billing;
    late List<List<SharedFile>> shared;

    setUp(() {
      billing = FakeBillingRepository(billing: sampleMyBilling());
      shared = [];
    });

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
            events: FakeEventRepository([
              testEvent(id: 'e1', title: 'Gala', status: EventStatus.published),
            ]),
            billing: billing,
            shareFiles: (files, {text}) async => shared.add(files),
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

    testWidgets('factures : filtre, détail, référence, PDF', (tester) async {
      await openAt(tester, AppRoutes.billing);
      await tapVisible(tester, find.byKey(const Key('billing-due')));
      expect(find.byKey(const Key('billing-invoices-page')), findsOneWidget);
      const due = 'aaaaaaaa-0000-0000-0000-00000000f001';
      const paid = 'aaaaaaaa-0000-0000-0000-00000000f002';
      expect(find.byKey(const Key('billing-invoice-$due')), findsOneWidget);
      expect(find.byKey(const Key('billing-invoice-$paid')), findsNothing);
      await tapVisible(
        tester,
        find.byKey(const Key('billing-invoices-filter-paid')),
      );
      expect(find.byKey(const Key('billing-invoice-$paid')), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const Key('billing-invoices-filter-all')),
      );
      await tapVisible(tester, find.byKey(const Key('billing-invoice-$due')));
      expect(
        find.byKey(const Key('billing-invoice-state-overdue')),
        findsOneWidget,
      );
      expect(find.text('F-AAAAAA'), findsOneWidget);
      expect(find.text('70 00 00 00'), findsOneWidget);
      expect(find.textContaining('Entrées 501 à 600'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('billing-invoice-pdf')));
      expect(shared.single.single.name, 'Facture-F-AAAAAA.pdf');
    });

    testWidgets("essai gratuit d'un pack", (tester) async {
      billing = FakeBillingRepository(
        catalog: [
          const BillingPack(
            id: 'pk-trial',
            name: 'Pro',
            system: BillingSystem.flat,
            status: PackStatus.published,
            monthlyPrice: 9000,
            durations: {BillingDuration.month: 9000},
            trialDays: 14,
          ),
        ],
      );
      await openAt(tester, AppRoutes.billingPacks);
      await tapVisible(tester, find.byKey(const Key('billing-trial-pk-trial')));
      expect(billing.calls, contains('trial pk-trial'));
      expect(find.byKey(const Key('billing-plan-name')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('billing-plan-state')),
          matching: find.text('Essai'),
        ),
        findsOneWidget,
      );
    });

    testWidgets("pas d'essai une deuxième fois", (tester) async {
      billing = FakeBillingRepository(
        billing: freeBilling(trialUsed: true),
        catalog: [
          const BillingPack(
            id: 'pk-trial',
            name: 'Pro',
            system: BillingSystem.flat,
            status: PackStatus.published,
            durations: {BillingDuration.month: 9000},
            trialDays: 14,
          ),
        ],
      );
      await openAt(tester, AppRoutes.billingPacks);
      expect(find.byKey(const Key('billing-trial-pk-trial')), findsNothing);
    });

    testWidgets("limite atteinte à l'usage : dépasser la limite", (
      tester,
    ) async {
      billing.eventBillingValue = const EventBilling(
        mode: EventBillingMode.usage,
        system: BillingSystem.usage,
        usagePackId: 'pu',
      );
      billing.catalogPacks.add(
        const BillingPack(
          id: 'pu2',
          name: 'Soirée+',
          system: BillingSystem.usage,
          status: PackStatus.published,
          entryPrice: 100,
        ),
      );
      final pu = billing.catalogPacks.indexWhere((p) => p.id == 'pu');
      billing.catalogPacks[pu] = const BillingPack(
        id: 'pu',
        name: 'Soirée',
        system: BillingSystem.usage,
        status: PackStatus.published,
        entryPrice: 150,
        options: {
          BillingOption.controllersPerEvent: PackOptionSetting(
            option: BillingOption.controllersPerEvent,
            included: 1,
            addonPrice: 1000,
          ),
        },
      );
      await openAt(tester, AppRoutes.home);
      captureBillingBlock(
        const supabase.PostgrestException(
          message: 'billing_limit_controllers_per_event',
          code: '54000',
          hint: '{"limit": 1, "system": "usage", "event": "e1"}',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('billing-block-sheet')), findsOneWidget);
      expect(
        find.text('Limite atteinte : Contrôleurs par événement'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('billing-block-offer')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('billing-block-exceed')));
      expect(billing.calls, contains('event-addon e1 controllers_per_event 1'));
      expect(find.byKey(const Key('billing-block-sheet')), findsNothing);
    });

    testWidgets('limite atteinte au forfait gratuit : voir les packs', (
      tester,
    ) async {
      await openAt(tester, AppRoutes.home);
      reportBillingBlock(
        const BillingBlock(
          kind: BillingBlockKind.limit,
          option: BillingOption.activeEvents,
          limit: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('billing-block-exceed')), findsNothing);
      expect(find.text('Valeur comprise dans votre pack : 2.'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('billing-block-packs')));
      expect(find.byKey(const Key('billing-choose-flat')), findsOneWidget);
    });

    testWidgets("fonction non comprise : import bloqué dans l'app", (
      tester,
    ) async {
      billing.eventBillingValue = const EventBilling(
        mode: EventBillingMode.inherit,
        system: BillingSystem.flat,
        features: {BillingOption.import: false},
      );
      await openAt(tester, AppRoutes.home);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Tickets'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tickets-import')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('billing-block-sheet')), findsOneWidget);
      expect(find.text('Import Excel / CSV : non compris'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('billing-block-later')));
      expect(find.byType(TicketImportPage), findsNothing);
    });

    testWidgets("facturation d'un événement : choisir un pack à l'usage", (
      tester,
    ) async {
      await openAt(tester, AppRoutes.eventDetail('e1'));
      await tapVisible(tester, find.byKey(const Key('event-billing')));
      expect(find.byKey(const Key('event-billing-open')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('event-billing-usage-pu')));
      await tapVisible(tester, find.byKey(const Key('event-billing-save')));
      expect(billing.calls, contains('event-set e1 usage pu'));
    });

    testWidgets('facturation figée : choix en lecture seule', (tester) async {
      billing.eventBillingValue = const EventBilling(
        mode: EventBillingMode.usage,
        system: BillingSystem.usage,
        usagePackId: 'pu',
        locked: true,
        packName: 'Soirée',
        estimate: UsageAmount(
          entries: 12,
          freeEntries: 2,
          billableEntries: 10,
          entriesAmount: 1500,
          amount: 1500,
        ),
      );
      await openAt(tester, AppRoutes.eventBilling('e1'));
      expect(find.byKey(const Key('event-billing-locked')), findsOneWidget);
      expect(find.byKey(const Key('event-billing-save')), findsNothing);
      expect(find.byKey(const Key('event-billing-estimate')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('event-billing-flat')));
      expect(billing.calls.where((c) => c.startsWith('event-set')), isEmpty);
    });
  });
}
