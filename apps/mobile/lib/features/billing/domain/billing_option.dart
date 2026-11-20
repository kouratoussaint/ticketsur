import 'package:ticketsur/l10n/l10n.dart';

/// Options d'un pack (ADR 0027). Liste fixe, identique au serveur
/// (`private.billing_numeric_options` et `private.billing_feature_options`) :
/// chaque option correspond à une vérification côté serveur ou dans l'app.
enum BillingOption {
  structures('structures', numeric: true),
  activeEvents('active_events', numeric: true),
  ticketsPerEvent('tickets_per_event', numeric: true),
  ticketsPerPeriod('tickets_per_period', numeric: true),
  membersPerStructure('members_per_structure', numeric: true),
  controllersPerEvent('controllers_per_event', numeric: true),
  assistedSend('assisted_send'),
  bulkSend('bulk_send'),
  import('import'),
  export('export'),
  printSheet('print_sheet'),
  customDesign('custom_design'),
  namedTickets('named_tickets'),
  liveDashboard('live_dashboard'),
  publicCatalog('public_catalog'),
  prioritySupport('priority_support');

  new(this.key, {this.numeric = false});

  /// Clé côté serveur.
  final String key;

  /// Option chiffrée (valeur incluse, null = illimité) ; sinon oui / non.
  final bool numeric;

  /// Option de clé [key], null si inconnue.
  static BillingOption? byKey(String key) {
    for (final option in values) {
      if (option.key == key) return option;
    }
    return null;
  }

  /// Libellé affiché.
  String label(AppLocalizations l10n) => switch (this) {
    structures => l10n.billingOptionStructures,
    activeEvents => l10n.billingOptionActiveEvents,
    ticketsPerEvent => l10n.billingOptionTicketsPerEvent,
    ticketsPerPeriod => l10n.billingOptionTicketsPerPeriod,
    membersPerStructure => l10n.billingOptionMembersPerStructure,
    controllersPerEvent => l10n.billingOptionControllersPerEvent,
    assistedSend => l10n.billingOptionAssistedSend,
    bulkSend => l10n.billingOptionBulkSend,
    import => l10n.billingOptionImport,
    export => l10n.billingOptionExport,
    printSheet => l10n.billingOptionPrintSheet,
    customDesign => l10n.billingOptionCustomDesign,
    namedTickets => l10n.billingOptionNamedTickets,
    liveDashboard => l10n.billingOptionLiveDashboard,
    publicCatalog => l10n.billingOptionPublicCatalog,
    prioritySupport => l10n.billingOptionPrioritySupport,
  };
}
