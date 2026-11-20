import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/features/catalog/presentation/catalog_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// « 9 000 FCFA ».
String money(AppLocalizations l10n, int amount) => formatFcfa(l10n, amount);

/// Date courte : « 20 nov. 2026 ».
String billingDate(DateTime instant) =>
    DateFormat.yMMMd(appLocaleTag).format(instant.toLocal());

String systemLabel(AppLocalizations l10n, BillingSystem system) =>
    switch (system) {
      BillingSystem.flat => l10n.billingSystemFlat,
      BillingSystem.usage => l10n.billingSystemUsage,
    };

TikeoTint systemTint(TikeoTints tints, BillingSystem system) =>
    switch (system) {
      BillingSystem.flat => tints.mint,
      BillingSystem.usage => tints.blue,
    };

String packStatusLabel(AppLocalizations l10n, PackStatus status) =>
    switch (status) {
      PackStatus.draft => l10n.billingPackDraft,
      PackStatus.published => l10n.billingPackPublished,
      PackStatus.archived => l10n.billingPackArchived,
    };

TikeoTint packStatusTint(TikeoTints tints, PackStatus status) =>
    switch (status) {
      PackStatus.draft => tints.amber,
      PackStatus.published => tints.green,
      PackStatus.archived => tints.gray,
    };

String durationLabel(AppLocalizations l10n, BillingDuration duration) =>
    switch (duration) {
      BillingDuration.month => l10n.billingDurationMonth,
      BillingDuration.quarter => l10n.billingDurationQuarter,
      BillingDuration.semester => l10n.billingDurationSemester,
      BillingDuration.year => l10n.billingDurationYear,
      BillingDuration.event => l10n.billingDurationEvent,
      BillingDuration.unlimited => l10n.billingDurationUnlimited,
    };

String channelLabel(AppLocalizations l10n, PaymentChannel channel) =>
    switch (channel) {
      PaymentChannel.orangeMoney => l10n.billingChannelOrange,
      PaymentChannel.moovMoney => l10n.billingChannelMoov,
      PaymentChannel.other => l10n.billingChannelOther,
    };

String featureStateLabel(AppLocalizations l10n, FeatureState state) =>
    switch (state) {
      FeatureState.included => l10n.billingFeatureIncluded,
      FeatureState.addon => l10n.billingFeatureAddon,
      FeatureState.unavailable => l10n.billingFeatureUnavailable,
    };

/// Suppléments d'une demande ou d'un abonnement : « +2 Membres… ».
String addonsLabel(AppLocalizations l10n, Map<String, int> addons) => [
  for (final MapEntry(:key, :value) in addons.entries)
    if (value > 0)
      l10n.billingAddonLine(
        value,
        BillingOption.byKey(key)?.label(l10n) ?? key,
      ),
].join(' · ');

/// Prix d'un pack : « 9 000 FCFA / mois » ou « 150 FCFA par entrée ».
String packPriceLabel(AppLocalizations l10n, BillingPack pack) =>
    switch (pack.system) {
      BillingSystem.flat when pack.isFree || (pack.monthlyPrice ?? 0) == 0 =>
        l10n.billingFree,
      BillingSystem.flat => l10n.billingPerMonth(
        money(l10n, pack.monthlyPrice!),
      ),
      BillingSystem.usage => l10n.billingPerEntry(
        money(l10n, pack.entryPrice ?? pack.tiers.firstOrNull?.price ?? 0),
      ),
    };

String billingFailureMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      BillingAdminFailure.forbidden => l10n.consoleForbidden,
      BillingAdminFailure.noteRequired => l10n.billingErrorNote,
      BillingAdminFailure.packInvalid => l10n.billingErrorPack,
      BillingAdminFailure.packProtected => l10n.billingErrorPackProtected,
      BillingAdminFailure.addonsInvalid => l10n.billingErrorAddons,
      BillingAdminFailure.settingsInvalid => l10n.billingErrorSettings,
      BillingAdminFailure.paymentInvalid => l10n.billingErrorPayment,
      BillingAdminFailure.alreadyProcessed => l10n.billingErrorProcessed,
      BillingAdminFailure.subscriptionInvalid => l10n.billingErrorEnd,
      BillingAdminFailure.choiceInvalid => l10n.billingErrorChoice,
      BillingAdminFailure.invoiceExists => l10n.billingErrorInvoiceExists,
      BillingAdminFailure.network => l10n.billingErrorNetwork,
      _ => l10n.consoleLoadError,
    };

/// Icône d'une option.
IconData optionIcon(BillingOption option) => switch (option) {
  BillingOption.structures => Icons.storefront_rounded,
  BillingOption.activeEvents => Icons.event_rounded,
  BillingOption.ticketsPerEvent => Icons.confirmation_number_rounded,
  BillingOption.ticketsPerPeriod => Icons.local_activity_rounded,
  BillingOption.membersPerStructure => Icons.groups_rounded,
  BillingOption.controllersPerEvent => Icons.qr_code_scanner_rounded,
  BillingOption.assistedSend => Icons.send_rounded,
  BillingOption.bulkSend => Icons.forward_to_inbox_rounded,
  BillingOption.import => Icons.upload_file_rounded,
  BillingOption.export => Icons.download_rounded,
  BillingOption.printSheet => Icons.print_rounded,
  BillingOption.customDesign => Icons.palette_rounded,
  BillingOption.namedTickets => Icons.badge_rounded,
  BillingOption.liveDashboard => Icons.insights_rounded,
  BillingOption.publicCatalog => Icons.travel_explore_rounded,
  BillingOption.prioritySupport => Icons.support_agent_rounded,
};
