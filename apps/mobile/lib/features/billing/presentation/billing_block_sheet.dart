import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/billing/application/billing_providers.dart';
import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_block.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/features/billing/presentation/my_pack_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Ouvre la feuille « Limite atteinte » (P8) à chaque blocage du pack
/// signalé par un dépôt ([billingBlocks]). Placé dans la coque connectée.
class BillingBlockListener extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<BillingBlockListener> createState() => _BillingBlockListenerState();
}

class _BillingBlockListenerState extends State<BillingBlockListener> {
  bool _open = false;

  @override
  void initState() {
    super.initState();
    billingBlocks.addListener(_onBlock);
    Toaster.muteErrors = () => billingBlockJustReported;
  }

  @override
  void dispose() {
    billingBlocks.removeListener(_onBlock);
    Toaster.muteErrors = null;
    super.dispose();
  }

  void _onBlock() {
    final block = billingBlocks.value;
    if (block == null || _open || !mounted) return;
    _open = true;
    // Après l'image en cours : la page qui a échoué finit son état.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _open = false;
        return;
      }
      await showBillingBlockSheet(context, block);
      _open = false;
    });
    // Le blocage peut arriver hors d'une image : en demander une.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// P8 · Limite atteinte : explication, « Dépasser la limite » (événement à
/// l'usage), suppléments ou packs.
Future<void> showBillingBlockSheet(BuildContext context, BillingBlock block) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => BillingBlockSheet(block: block),
    );

/// Vérifie qu'une fonction de l'app (envoi en série, import, planche A4) est
/// comprise pour l'événement ; sinon ouvre la feuille et renvoie faux.
/// Un échec de lecture laisse faire (le serveur ne bloque pas ces fonctions).
Future<bool> billingAllows(
  WidgetRef ref,
  String eventId,
  BillingOption option,
) async {
  final EventBilling billing;
  try {
    billing = await ref.read(eventBillingProvider(eventId).future);
  } on Object {
    return true;
  }
  if (billing.allows(option)) return true;
  reportBillingBlock(
    BillingBlock(
      kind: BillingBlockKind.option,
      option: option,
      system: billing.system,
      eventId: billing.system == BillingSystem.usage ? eventId : null,
    ),
  );
  return false;
}

/// Ouvre [route] si [option] est comprise pour l'événement (sinon la feuille
/// « Limite atteinte » s'ouvre).
Future<void> pushIfBillingAllows(
  BuildContext context,
  WidgetRef ref,
  String eventId,
  BillingOption option,
  String route,
) async {
  final router = GoRouter.of(context);
  if (await billingAllows(ref, eventId, option)) {
    unawaited(router.push(route));
  }
}

class BillingBlockSheet extends ConsumerStatefulWidget {
  const new({required this.block, super.key});

  final BillingBlock block;

  @override
  ConsumerState<BillingBlockSheet> createState() => _BillingBlockSheetState();
}

class _BillingBlockSheetState extends ConsumerState<BillingBlockSheet> {
  bool _busy = false;
  String? _error;

  BillingBlock get block => widget.block;

  /// Supplément proposé pour un événement à l'usage : réglage de l'option
  /// dans le pack de l'événement.
  PackOptionSetting? _usageAddon(
    EventBilling? billing,
    List<BillingPack>? catalog,
  ) {
    final option = block.option;
    if (option == null || billing == null || catalog == null) return null;
    final pack = catalog.where((p) => p.id == billing.usagePackId).firstOrNull;
    final setting = pack?.options[option];
    if (setting == null || !setting.addonAllowed) return null;
    if (!option.numeric && setting.state != FeatureState.addon) return null;
    return setting;
  }

  Future<void> _exceed(PackOptionSetting setting) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(billingRepositoryProvider)
          .addEventAddon(block.eventId!, setting.option, 1);
      ref.invalidate(eventBillingProvider(block.eventId!));
      toast.success(l10n.billingBlockAdded);
      navigator.pop();
    } on Object catch (error) {
      if (mounted) setState(() => _error = promoterBillingMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _go(String route) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    unawaited(router.push(route));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final role = ref.watch(activeOrganizationProvider)?.role;
    final owner = role == MemberRole.owner;
    final canExceed = owner || role == MemberRole.manager;
    final eventId = block.eventId;
    final usageEvent =
        block.system == BillingSystem.usage && eventId != null && canExceed;
    final eventBilling = usageEvent
        ? ref.watch(eventBillingProvider(eventId)).value
        : null;
    final catalog = usageEvent ? ref.watch(billingCatalogProvider).value : null;
    final addon = _usageAddon(eventBilling, catalog);
    final myBilling = owner && block.system == BillingSystem.flat
        ? ref.watch(myBillingProvider).value
        : null;
    final flatAddon =
        myBilling != null &&
        myBilling.plan.isPaid &&
        (block.option == null ||
            (myBilling.plan.pack.options[block.option]?.addonAllowed ?? false));
    final optionLabel = block.option?.label(l10n) ?? '';
    final (title, body, icon, tint) = switch (block.kind) {
      BillingBlockKind.limit => (
        l10n.billingBlockLimitTitle(optionLabel),
        block.limit == null ? null : l10n.billingBlockLimitBody(block.limit!),
        Icons.speed_rounded,
        tints.red,
      ),
      BillingBlockKind.option => (
        l10n.billingBlockOptionTitle(optionLabel),
        l10n.billingBlockOptionBody,
        Icons.lock_rounded,
        tints.amber,
      ),
      BillingBlockKind.overdue => (
        l10n.billingBlockOverdueTitle,
        l10n.billingOverdueBody,
        Icons.receipt_long_rounded,
        tints.red,
      ),
      BillingBlockKind.usagePackMissing => (
        l10n.billingBlockUsagePackTitle,
        l10n.billingBlockUsagePackBody,
        Icons.tune_rounded,
        tints.amber,
      ),
    };
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('billing-block-sheet'),
        padding: const EdgeInsets.fromLTRB(
          TikeoSizes.screenMargin,
          0,
          TikeoSizes.screenMargin,
          TikeoSizes.screenMargin,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tint.background,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(icon, color: tint.icon),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    key: const Key('billing-block-title'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              TintedBanner(
                tint: tints.red,
                icon: Icons.error_rounded,
                title: error,
              ),
            ],
            const SizedBox(height: TikeoSizes.cardGap),
            if (addon != null) ...[
              TikeoCard(
                key: const Key('billing-block-offer'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.billingBlockAddonOffer(
                        addon.option.numeric
                            ? '+${addon.addonStep} $optionLabel'
                            : optionLabel,
                        money(l10n, addon.addonPrice!),
                      ),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      l10n.billingBlockAddonInvoice,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TikeoSizes.cardGap),
              TikeoPrimaryButton(
                key: const Key('billing-block-exceed'),
                busy: _busy,
                onPressed: _busy ? null : () => unawaited(_exceed(addon)),
                icon: Icons.add_circle_rounded,
                label: l10n.billingBlockExceed,
              ),
              const SizedBox(height: 8),
            ],
            if (owner) ...[
              if (block.kind == BillingBlockKind.overdue)
                TikeoPrimaryButton(
                  key: const Key('billing-block-invoices'),
                  onPressed: () => _go(AppRoutes.billingInvoices),
                  icon: Icons.receipt_long_rounded,
                  label: l10n.billingBlockSeeInvoices,
                )
              else if (block.kind == BillingBlockKind.usagePackMissing &&
                  eventId != null)
                TikeoPrimaryButton(
                  key: const Key('billing-block-event'),
                  onPressed: () => _go(AppRoutes.eventBilling(eventId)),
                  icon: Icons.tune_rounded,
                  label: l10n.billingBlockChooseUsagePack,
                )
              else ...[
                if (flatAddon)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TikeoPrimaryButton(
                      key: const Key('billing-block-addons'),
                      onPressed: () => _go(AppRoutes.billingAddonsCurrent),
                      icon: Icons.add_circle_rounded,
                      label: l10n.billingAddonsTitle,
                    ),
                  ),
                if (addon == null && !flatAddon)
                  TikeoPrimaryButton(
                    key: const Key('billing-block-packs'),
                    onPressed: () => _go(AppRoutes.billingPacks),
                    icon: Icons.workspace_premium_rounded,
                    label: l10n.billingBlockSeePacks,
                  )
                else
                  OutlinedButton(
                    key: const Key('billing-block-packs'),
                    onPressed: () => _go(AppRoutes.billingPacks),
                    child: Text(l10n.billingBlockSeePacks),
                  ),
              ],
            ] else if (addon == null)
              TintedBanner(
                key: const Key('billing-block-ask-owner'),
                tint: tints.blue,
                icon: Icons.info_rounded,
                title: l10n.billingBlockAskOwner,
              ),
            const SizedBox(height: 4),
            TextButton(
              key: const Key('billing-block-later'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.billingBlockLater),
            ),
          ],
        ),
      ),
    );
  }
}
