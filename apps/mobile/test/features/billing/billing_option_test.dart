import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticketsur/features/admin/presentation/audit_labels.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/l10n/gen/app_localizations_fr.dart';

void main() {
  final l10n = AppLocalizationsFr();

  test('options : même liste que le serveur, dans le même ordre', () {
    final sql = File(
      '../../supabase/migrations/20261120003600_billing_base.sql',
    ).readAsStringSync();
    List<String> keysOf(String function) {
      final body = RegExp(
        'function private\\.$function\\(\\).*?array\\[(.*?)\\]',
        dotAll: true,
      ).firstMatch(sql)!.group(1)!;
      return RegExp("'([a-z_]+)'")
          .allMatches(body)
          .map((m) => m.group(1)!)
          .toList();
    }

    expect(
      BillingOption.values.where((o) => o.numeric).map((o) => o.key),
      keysOf('billing_numeric_options'),
    );
    expect(
      BillingOption.values.where((o) => !o.numeric).map((o) => o.key),
      keysOf('billing_feature_options'),
    );
  });

  test('options : clé retrouvée, libellé en français', () {
    expect(BillingOption.byKey('live_dashboard'), BillingOption.liveDashboard);
    expect(BillingOption.byKey('teleportation'), isNull);
    expect(BillingOption.ticketsPerPeriod.label(l10n), 'Tickets par période');
  });

  test('journal : actions de facturation lisibles', () {
    expect(
      auditActionLabel(l10n, 'billing.invoice_issued'),
      "Facture à l'usage émise",
    );
    expect(
      auditActionLabel(l10n, 'admin.billing_request_activated'),
      'Demande validée, paiement reçu',
    );
    expect(
      auditDetails(l10n, {
        'option': 'controllers_per_event',
        'units': 1,
        'duration': 'quarter',
        'channel': 'orange_money',
      }),
      'option : Contrôleurs par événement · tranches : 1 · '
      'durée : trimestriel · canal : Orange Money',
    );
  });
}
