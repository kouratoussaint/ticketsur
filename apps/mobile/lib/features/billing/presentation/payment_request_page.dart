import 'dart:async';

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/billing/application/billing_providers.dart';
import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/features/billing/presentation/my_pack_page.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// P5 · Paiement, puis P6 · En attente de validation, pour une demande.
class PaymentRequestPage extends ConsumerStatefulWidget {
  const new({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<PaymentRequestPage> createState() => _PaymentRequestPageState();
}

class _PaymentRequestPageState extends ConsumerState<PaymentRequestPage> {
  final _transaction = TextEditingController();
  PaymentChannel _channel = PaymentChannel.orangeMoney;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _transaction.dispose();
    super.dispose();
  }

  Future<void> _copy(String text) async {
    final toast = Toaster.of(context);
    final l10n = context.l10n;
    await Clipboard.setData(ClipboardData(text: text));
    toast.info(l10n.billingCopied);
  }

  Future<void> _declare() async {
    final l10n = context.l10n;
    final transaction = _transaction.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(billingRepositoryProvider)
          .declarePayment(
            widget.requestId,
            _channel,
            transaction.isEmpty ? null : transaction,
          );
      ref.invalidate(myBillingProvider);
    } on Object catch (error) {
      if (mounted) setState(() => _error = promoterBillingMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    try {
      await ref.read(billingRepositoryProvider).cancelRequest(widget.requestId);
      ref.invalidate(myBillingProvider);
      toast.success(l10n.billingRequestCancelled);
      if (mounted) context.popOr(AppRoutes.billing);
    } on Object catch (error) {
      toast.error(promoterBillingMessage(l10n, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billing = ref.watch(myBillingProvider);
    final value = billing.value;
    final request = value?.requestById(widget.requestId);
    final pending = request?.status == RequestStatus.pending;
    return Scaffold(
      appBar: TikeoAppBar(
        title: Text(
          pending && !(request?.declared ?? false)
              ? l10n.billingPaymentTitle
              : l10n.billingRequestTitle,
        ),
        leading: BackButton(onPressed: () => context.popOr(AppRoutes.billing)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          TikeoSizes.screenMargin,
          TikeoSizes.cardGap,
          TikeoSizes.screenMargin,
          MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
        ),
        child: switch ((value, request)) {
          (final MyBilling billing, final MyBillingRequest request)
              when request.status == RequestStatus.pending &&
                  !request.declared =>
            _pay(context, billing, request),
          (_, final MyBillingRequest request) => _status(context, request),
          (final MyBilling _, null) => Text(
            l10n.billingErrorProcessed,
            key: const Key('billing-request-missing'),
          ),
          _ when billing.hasError => TintedBanner(
            tint: context.tints.red,
            icon: Icons.cloud_off_rounded,
            title: promoterBillingMessage(l10n, billing.error!),
          ),
          _ => const Shimmer(
            child: SkeletonBox(height: 320, radius: TikeoRadii.card),
          ),
        },
      ),
    );
  }

  /// P5 : montant, référence, numéros, identifiant reçu par SMS.
  Widget _pay(
    BuildContext context,
    MyBilling billing,
    MyBillingRequest request,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final payment = billing.payment;
    Widget number(PaymentChannel channel, String? value, TikeoTint tint) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TikeoCard(
            padding: const EdgeInsets.all(4),
            child: SettingsRow(
              key: Key('billing-pay-${channel.wireName}'),
              icon: Icons.phone_android_rounded,
              tint: tint,
              title: channelLabel(l10n, channel),
              subtitle: value ?? l10n.billingNumberMissing,
              trailing: value == null
                  ? null
                  : IconButton(
                      tooltip: l10n.billingCopy,
                      onPressed: () => unawaited(_copy(value)),
                      icon: const Icon(Icons.copy_rounded),
                    ),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error case final error?) ...[
          TintedBanner(
            key: const Key('billing-pay-error'),
            tint: tints.red,
            icon: Icons.error_rounded,
            title: error,
          ),
          const SizedBox(height: TikeoSizes.cardGap),
        ],
        TikeoCard(
          key: const Key('billing-pay-summary'),
          child: Column(
            children: [
              Text(l10n.billingAmountToPay, style: theme.textTheme.bodyMedium),
              Text(
                money(l10n, request.amount),
                key: const Key('billing-pay-amount'),
                style: TikeoTextStyles.bigNumber.copyWith(
                  color: tints.mint.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.billingReferenceToGive,
                style: theme.textTheme.bodySmall,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // La référence reste sur une ligne, réduite s'il le faut.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        request.reference,
                        key: const Key('billing-pay-reference'),
                        style: TikeoTextStyles.ticketNumber.copyWith(
                          fontSize: 24,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('billing-pay-copy'),
                    tooltip: l10n.billingCopy,
                    onPressed: () => unawaited(_copy(request.reference)),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: TikeoSizes.sectionGap),
        SectionHeader(
          title: l10n.billingPayStep1,
          icon: Icons.send_to_mobile_rounded,
        ),
        const SizedBox(height: 8),
        number(
          PaymentChannel.orangeMoney,
          payment.orangeMoneyNumber,
          tints.orange,
        ),
        number(PaymentChannel.moovMoney, payment.moovMoneyNumber, tints.blue),
        if (payment.beneficiary != null || payment.instructions != null)
          TikeoCard(
            key: const Key('billing-pay-beneficiary'),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (payment.beneficiary case final name?)
                  Text(
                    l10n.billingBeneficiary(name),
                    style: theme.textTheme.bodySmall,
                  ),
                if (payment.instructions case final text?)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(text, style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
        const SizedBox(height: TikeoSizes.sectionGap),
        SectionHeader(title: l10n.billingPayStep2, icon: Icons.sms_rounded),
        const SizedBox(height: 8),
        TikeoCard(
          key: const Key('billing-pay-form'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<PaymentChannel>(
                showSelectedIcon: false,
                segments: [
                  for (final channel in [
                    PaymentChannel.orangeMoney,
                    PaymentChannel.moovMoney,
                  ])
                    ButtonSegment(
                      value: channel,
                      label: Text(
                        channelLabel(l10n, channel),
                        key: Key('billing-pay-channel-${channel.wireName}'),
                      ),
                    ),
                ],
                selected: {_channel},
                onSelectionChanged: (value) =>
                    setState(() => _channel = value.single),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('billing-pay-transaction'),
                controller: _transaction,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: l10n.billingTransaction,
                  helperText: l10n.billingTransactionHelp,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TintedBanner(
          tint: tints.blue,
          icon: Icons.info_rounded,
          title: l10n.billingActivationDelay,
        ),
        const SizedBox(height: TikeoSizes.cardGap),
        TikeoPrimaryButton(
          key: const Key('billing-pay-done'),
          busy: _busy,
          onPressed: _busy ? null : () => unawaited(_declare()),
          icon: Icons.check_circle_rounded,
          label: l10n.billingIPaid,
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('billing-pay-cancel'),
          onPressed: _busy ? null : () => unawaited(_cancel()),
          child: Text(l10n.billingCancelRequest),
        ),
      ],
    );
  }

  /// P6 : en attente, activée, refusée ou annulée.
  Widget _status(BuildContext context, MyBillingRequest request) {
    final l10n = context.l10n;
    final tints = context.tints;
    final theme = Theme.of(context);
    final (title, tint, icon) = switch (request.status) {
      RequestStatus.pending => (
        l10n.billingWaitingTitle,
        tints.amber,
        Icons.hourglass_top_rounded,
      ),
      RequestStatus.activated => (
        l10n.billingActivatedTitle,
        tints.green,
        Icons.verified_rounded,
      ),
      RequestStatus.refused => (
        l10n.billingRefusedTitle,
        tints.red,
        Icons.block_rounded,
      ),
      RequestStatus.cancelled => (
        l10n.billingCancelledTitle,
        tints.gray,
        Icons.cancel_rounded,
      ),
    };
    final steps = [
      (l10n.billingStepCreated, true),
      (l10n.billingStepDeclared, request.declared),
      (
        l10n.billingStepChecked,
        request.status == RequestStatus.activated ||
            request.status == RequestStatus.refused,
      ),
      (l10n.billingStepActivated, request.status == RequestStatus.activated),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TintedBanner(
          key: Key('billing-request-${request.status.wireName}'),
          tint: tint,
          icon: icon,
          title: title,
          body: l10n.billingPendingBody(
            request.reference,
            money(l10n, request.amount),
          ),
        ),
        const SizedBox(height: TikeoSizes.cardGap),
        if (request.status == RequestStatus.pending ||
            request.status == RequestStatus.activated)
          TikeoCard(
            key: const Key('billing-request-steps'),
            child: Column(
              children: [
                for (final (i, (label, done)) in steps.indexed)
                  Row(
                    children: [
                      Icon(
                        done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: done ? tints.green.icon : tints.gray.icon,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: i == 0 ? 4 : 8,
                          ),
                          child: Text(
                            label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: done
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        const SizedBox(height: TikeoSizes.cardGap),
        TikeoPrimaryButton(
          key: const Key('billing-request-back'),
          onPressed: () => context.go(AppRoutes.billing),
          icon: Icons.arrow_back_rounded,
          label: l10n.billingBackToMyPack,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('billing-request-support'),
          onPressed: () => unawaited(context.push(AppRoutes.supportNew)),
          icon: const Icon(Icons.support_agent_rounded),
          label: Text(l10n.billingContactSupport),
        ),
      ],
    );
  }
}
