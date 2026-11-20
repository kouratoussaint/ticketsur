import 'dart:async';

import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/billing/application/billing_admin_providers.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/features/billing/presentation/console_packs_page.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// C6 · Réglages de paiement : numéros Orange Money et Moov, consigne,
/// délais de la facturation.
class ConsolePaymentSettingsPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsolePaymentSettingsPage> createState() =>
      _ConsolePaymentSettingsPageState();
}

class _ConsolePaymentSettingsPageState
    extends ConsumerState<ConsolePaymentSettingsPage> {
  final _orange = TextEditingController();
  final _moov = TextEditingController();
  final _beneficiary = TextEditingController();
  final _instructions = TextEditingController();
  final _paymentDays = TextEditingController();
  final _invoiceHours = TextEditingController();
  final _reminderDays = TextEditingController();
  final _graceDays = TextEditingController();
  bool _ready = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _orange,
      _moov,
      _beneficiary,
      _instructions,
      _paymentDays,
      _invoiceHours,
      _reminderDays,
      _graceDays,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _init(BillingSettings settings) {
    if (_ready) return;
    _ready = true;
    _orange.text = settings.orangeMoneyNumber ?? '';
    _moov.text = settings.moovMoneyNumber ?? '';
    _beneficiary.text = settings.beneficiary ?? '';
    _instructions.text = settings.instructions ?? '';
    _paymentDays.text = '${settings.usagePaymentDays}';
    _invoiceHours.text = '${settings.invoiceDelayHours}';
    _reminderDays.text = '${settings.reminderDays}';
    _graceDays.text = '${settings.graceDays}';
  }

  String? _text(TextEditingController controller) =>
      controller.text.trim().isEmpty ? null : controller.text.trim();

  Future<void> _save(BillingSettings current) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    int number(TextEditingController controller, int fallback) =>
        int.tryParse(controller.text.trim()) ?? fallback;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(billingAdminRepositoryProvider)
          .saveSettings(
            BillingSettings(
              orangeMoneyNumber: _text(_orange),
              moovMoneyNumber: _text(_moov),
              beneficiary: _text(_beneficiary),
              instructions: _text(_instructions),
              usagePaymentDays: number(_paymentDays, current.usagePaymentDays),
              invoiceDelayHours: number(
                _invoiceHours,
                current.invoiceDelayHours,
              ),
              reminderDays: number(_reminderDays, current.reminderDays),
              graceDays: number(_graceDays, current.graceDays),
            ),
          );
      ref.invalidate(adminBillingProvider);
      toast.success(l10n.billingSettingsSaved);
      if (mounted) context.popOr(AppRoutes.console);
    } on Object catch (error) {
      if (mounted) setState(() => _error = billingFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billing = ref.watch(adminBillingProvider);
    final settings = billing.value?.settings;
    if (settings == null) {
      return Scaffold(
        appBar: TikeoAppBar(title: Text(l10n.billingSettingsTitle)),
        body: Padding(
          padding: const EdgeInsets.all(TikeoSizes.screenMargin),
          child: switch (billing) {
            AsyncError(:final error) => BillingLoadError(
              error: error,
              onRetry: () => ref.invalidate(adminBillingProvider),
            ),
            _ => const BillingLoading(),
          },
        ),
      );
    }
    _init(settings);
    Widget field(
      String key,
      TextEditingController controller,
      String label, {
      bool number = false,
      bool phone = false,
      String? suffix,
      String? helper,
      int? maxLength,
      int maxLines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        key: Key('billing-settings-$key'),
        controller: controller,
        keyboardType: number
            ? TextInputType.number
            : phone
            ? TextInputType.phone
            : TextInputType.text,
        inputFormatters: number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        maxLength: maxLength,
        minLines: maxLines > 1 ? 2 : 1,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          helperText: helper,
        ),
      ),
    );
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.billingSettingsTitle)),
      body: SingleChildScrollView(
        key: const Key('billing-settings'),
        padding: EdgeInsets.fromLTRB(
          TikeoSizes.screenMargin,
          TikeoSizes.cardGap,
          TikeoSizes.screenMargin,
          MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error case final error?) ...[
              TintedBanner(
                key: const Key('billing-settings-error'),
                tint: context.tints.red,
                icon: Icons.error_rounded,
                title: error,
              ),
              const SizedBox(height: TikeoSizes.cardGap),
            ],
            SectionHeader(
              title: l10n.billingSettingsNumbers,
              icon: Icons.phone_android_rounded,
            ),
            const SizedBox(height: 8),
            TikeoCard(
              child: Column(
                children: [
                  field(
                    'orange',
                    _orange,
                    l10n.billingChannelOrange,
                    phone: true,
                    maxLength: 30,
                  ),
                  field(
                    'moov',
                    _moov,
                    l10n.billingChannelMoov,
                    phone: true,
                    maxLength: 30,
                  ),
                  field(
                    'beneficiary',
                    _beneficiary,
                    l10n.billingSettingsBeneficiary,
                    maxLength: 80,
                  ),
                  field(
                    'instructions',
                    _instructions,
                    l10n.billingSettingsInstructions,
                    maxLength: 500,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: TikeoSizes.sectionGap),
            SectionHeader(
              title: l10n.billingSettingsDelays,
              icon: Icons.schedule_rounded,
            ),
            const SizedBox(height: 8),
            TikeoCard(
              child: Column(
                children: [
                  field(
                    'payment-days',
                    _paymentDays,
                    l10n.billingSettingsPaymentDays,
                    number: true,
                    suffix: l10n.billingDaysSuffix,
                    helper: l10n.billingSettingsPaymentDaysHelp,
                  ),
                  field(
                    'invoice-hours',
                    _invoiceHours,
                    l10n.billingSettingsInvoiceHours,
                    number: true,
                    suffix: l10n.billingHoursSuffix,
                    helper: l10n.billingSettingsInvoiceHoursHelp,
                  ),
                  field(
                    'reminder-days',
                    _reminderDays,
                    l10n.billingSettingsReminderDays,
                    number: true,
                    suffix: l10n.billingDaysSuffix,
                  ),
                  field(
                    'grace-days',
                    _graceDays,
                    l10n.billingSettingsGraceDays,
                    number: true,
                    suffix: l10n.billingDaysSuffix,
                  ),
                ],
              ),
            ),
            const SizedBox(height: TikeoSizes.sectionGap),
            TikeoPrimaryButton(
              key: const Key('billing-settings-save'),
              busy: _busy,
              onPressed: _busy ? null : () => unawaited(_save(settings)),
              icon: Icons.save_rounded,
              label: l10n.billingSettingsSave,
            ),
          ],
        ),
      ),
    );
  }
}
