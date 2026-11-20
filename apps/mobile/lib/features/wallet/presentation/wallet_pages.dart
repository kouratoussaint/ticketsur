import 'dart:async';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/empty_state.dart';
import 'package:ticketsur/design_system/widgets/status_chip.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_cover.dart';
import 'package:ticketsur/features/scanner/presentation/camera/scan_camera.dart';
import 'package:ticketsur/features/ticket_templates/presentation/ticket_artwork.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/wallet/application/wallet_providers.dart';
import 'package:ticketsur/features/wallet/domain/wallet.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _when(DateTime instant) => formatDateAtTime(instant.toLocal());

String walletFailureMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      WalletFailure.invalidCode => l10n.walletErrorInvalid,
      WalletFailure.unknown => l10n.walletErrorUnknown,
      WalletFailure.revoked => l10n.walletErrorRevoked,
      WalletFailure.claimed => l10n.walletErrorClaimed,
      WalletFailure.network => l10n.walletErrorNetwork,
      _ => l10n.walletErrorOther,
    };

StatusChip walletStatusChip(AppLocalizations l10n, TicketStatus status) =>
    switch (status) {
      // Teintes des statuts de ticket (direction artistique, section 3).
      TicketStatus.issued => StatusChip(
        label: l10n.walletStatusValid,
        tone: StatusTone.info,
        icon: Icons.schedule_rounded,
      ),
      TicketStatus.redeemed => StatusChip(
        label: l10n.walletStatusUsed,
        tone: StatusTone.positive,
        icon: Icons.check_circle_rounded,
      ),
      TicketStatus.revoked => StatusChip(
        label: l10n.walletStatusRevoked,
        tone: StatusTone.danger,
        icon: Icons.cancel_rounded,
      ),
      TicketStatus.expired => StatusChip(
        label: l10n.walletStatusExpired,
        tone: StatusTone.neutral,
        icon: Icons.hourglass_empty_rounded,
      ),
    };

/// « Mes tickets » : onglet d'un compte classique, page empilée pour un
/// membre d'une structure ([showBack]).
class WalletPage extends ConsumerWidget {
  const new({this.showBack = false, super.key});

  final bool showBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wallet = ref.watch(walletProvider);
    final now = DateTime.now().toUtc();
    void add() => unawaited(context.push(AppRoutes.walletAdd));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBack
            ? BackButton(onPressed: () => context.popOr(AppRoutes.profile))
            : null,
        title: Text(l10n.walletTitle),
      ),
      floatingActionButton: switch (wallet.value) {
        WalletState(:final tickets) when tickets.isNotEmpty =>
          FloatingActionButton.extended(
            key: const Key('wallet-add'),
            heroTag: 'wallet-add',
            onPressed: add,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.walletAdd),
          ),
        _ => null,
      },
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.read(walletProvider.notifier).reload();
          } on Object {
            // L'échec s'affiche dans la page.
          }
        },
        child: switch (wallet) {
          AsyncData(value: WalletState(:final tickets)) when tickets.isEmpty =>
            EmptyState(
              icon: Icons.confirmation_number_rounded,
              title: l10n.walletEmptyTitle,
              titleKey: const Key('wallet-empty'),
              body: l10n.walletEmptyBody,
              actionLabel: l10n.walletAdd,
              actionKey: const Key('wallet-empty-add'),
              onAction: add,
              scrollable: true,
            ),
          AsyncData(:final value) => ListView(
            key: const Key('wallet-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              TicketSurSpacing.md,
              TicketSurSpacing.sm,
              TicketSurSpacing.md,
              96,
            ),
            children: [
              if (value.savedAt case final saved?)
                Card(
                  key: const Key('wallet-offline'),
                  color: context.palette.warningContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.cloud_off_rounded,
                      color: context.palette.warningText,
                    ),
                    title: Text(
                      l10n.walletOffline(_when(saved)),
                      style: TextStyle(color: context.palette.warningText),
                    ),
                  ),
                ),
              for (final (title, past) in [
                (l10n.walletUpcoming, false),
                (l10n.walletPast, true),
              ])
                if (value.tickets.any((t) => t.isPastAt(now) == past)) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TicketSurSpacing.xs,
                      TicketSurSpacing.md,
                      TicketSurSpacing.xs,
                      TicketSurSpacing.xs,
                    ),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final ticket in value.tickets)
                    if (ticket.isPastAt(now) == past)
                      _WalletTile(ticket: ticket),
                ],
            ],
          ),
          AsyncError(:final error) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(TicketSurSpacing.xl),
            children: [
              Text(
                error == WalletFailure.network
                    ? l10n.walletErrorNetwork
                    : l10n.walletLoadError,
                key: const Key('wallet-error'),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => ref.invalidate(walletProvider),
                child: Text(l10n.walletRetry),
              ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const new({required this.ticket});

  final WalletTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final event = ticket.event;
    return Card(
      key: Key('wallet-ticket-${ticket.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(context.push(AppRoutes.walletTicket(ticket.id))),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: EventCover.forEvent(event, aspectRatio: 0.9),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(TicketSurSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: TicketSurSpacing.xxs),
                    Text(
                      formatEventRange(event),
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.mutedText,
                      ),
                    ),
                    if (event.venue ?? event.city case final place?)
                      Text(
                        place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: context.palette.mutedText,
                        ),
                      ),
                    const SizedBox(height: TicketSurSpacing.xs),
                    Wrap(
                      spacing: TicketSurSpacing.xs,
                      runSpacing: TicketSurSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        walletStatusChip(l10n, ticket.status),
                        Text(ticket.categoryName, style: textTheme.labelMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ajouter un ticket : scanner, choisir une image ou coller le code.
class WalletAddPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<WalletAddPage> createState() => _WalletAddPageState();
}

class _WalletAddPageState extends ConsumerState<WalletAddPage> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _claim(String code) async {
    if (_busy) return;
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await ref.read(walletProvider.notifier).claim(code);
      toast.success(l10n.walletAdded);
      if (mounted) context.pushReplacement(AppRoutes.walletTicket(id));
    } on Object catch (error) {
      if (mounted) setState(() => _error = walletFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fromImage() async {
    final l10n = context.l10n;
    final code = await ref.read(qrFromImageProvider)();
    if (!mounted) return;
    if (code == null) {
      setState(() => _error = l10n.walletNoQrInImage);
      return;
    }
    await _claim(code);
  }

  Future<void> _scan() async {
    final code = await context.push<String>(AppRoutes.walletScan);
    if (code != null && mounted) await _claim(code);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text case final text? when mounted) _code.text = text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget option({
      required Key key,
      required IconData icon,
      required String title,
      required String hint,
      required VoidCallback onTap,
    }) => Card(
      child: ListTile(
        key: key,
        enabled: !_busy,
        leading: Icon(icon, color: context.palette.accentText),
        title: Text(title),
        subtitle: Text(hint),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walletAddTitle)),
      body: ListView(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: [
          Text(l10n.walletAddIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: TicketSurSpacing.md),
          if (_error case final error?) ...[
            Card(
              key: const Key('wallet-add-error'),
              color: theme.colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(
                  Icons.error_outline_rounded,
                  color: theme.colorScheme.onErrorContainer,
                ),
                title: Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
          ],
          if (_busy) const LinearProgressIndicator(),
          option(
            key: const Key('wallet-add-scan'),
            icon: Icons.qr_code_scanner_rounded,
            title: l10n.walletAddScan,
            hint: l10n.walletAddScanHint,
            onTap: () => unawaited(_scan()),
          ),
          option(
            key: const Key('wallet-add-image'),
            icon: Icons.image_rounded,
            title: l10n.walletAddImage,
            hint: l10n.walletAddImageHint,
            onTap: () => unawaited(_fromImage()),
          ),
          const SizedBox(height: TicketSurSpacing.lg),
          Text(l10n.walletAddPaste, style: theme.textTheme.titleSmall),
          const SizedBox(height: TicketSurSpacing.xs),
          TextField(
            key: const Key('wallet-add-code'),
            controller: _code,
            enabled: !_busy,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: l10n.walletAddPasteHint,
              suffixIcon: IconButton(
                tooltip: l10n.walletAddPaste,
                onPressed: () => unawaited(_paste()),
                icon: const Icon(Icons.content_paste_rounded),
              ),
            ),
            onSubmitted: (value) => unawaited(_claim(value)),
          ),
          const SizedBox(height: TicketSurSpacing.sm),
          FilledButton(
            key: const Key('wallet-add-submit'),
            onPressed: _busy ? null : () => unawaited(_claim(_code.text)),
            child: Text(l10n.walletAddPasteSubmit),
          ),
        ],
      ),
    );
  }
}

/// Caméra plein écran : renvoie le premier QR lu.
class WalletScanPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<WalletScanPage> createState() => _WalletScanPageState();
}

class _WalletScanPageState extends ConsumerState<WalletScanPage> {
  bool _done = false;

  void _onCode(String code) {
    if (_done || !walletTokenPattern.hasMatch(code.trim())) return;
    _done = true;
    context.pop(code.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final camera = ref.watch(scanCameraBuilderProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: camera(
        onCode: _onCode,
        onManualEntry: () => context.pop(),
        header: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                key: const Key('wallet-scan-close'),
                color: Colors.white,
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: Text(
                  l10n.walletAddScanTitle,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        footer: const SizedBox(height: TicketSurSpacing.xl),
      ),
    );
  }
}

/// Un ticket de « Mes tickets » : QR à présenter à l'entrée.
class WalletTicketPage extends ConsumerWidget {
  const new({required this.ticketId, super.key});

  final String ticketId;

  Future<void> _release(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final confirmed = await showConsoleConfirm(
      context,
      title: l10n.walletReleaseTitle,
      body: l10n.walletReleaseBody,
      confirmLabel: l10n.walletRelease,
      needsReason: false,
      confirmKey: const Key('wallet-release-confirm'),
    );
    if (confirmed == null) return;
    try {
      await ref.read(walletProvider.notifier).release(ticketId);
      toast.success(l10n.walletReleased);
      if (context.mounted) context.popOr(AppRoutes.walletTab);
    } on Object catch (error) {
      toast.error(walletFailureMessage(l10n, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(walletProvider);
    final ticket = state.value?.tickets
        .where((t) => t.id == ticketId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.walletTitle),
        leading: BackButton(
          onPressed: () => context.popOr(AppRoutes.walletTab),
        ),
      ),
      body: switch (ticket) {
        null when state.isLoading => const Center(
          child: CircularProgressIndicator(),
        ),
        null => Center(
          child: Text(l10n.walletNotFound, key: const Key('wallet-not-found')),
        ),
        final t => ListView(
          key: Key('wallet-detail-${t.id}'),
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          children: [
            if (state.value?.savedAt case final saved?) ...[
              Text(
                l10n.walletOffline(_when(saved)),
                key: const Key('wallet-offline'),
                style: textTheme.bodySmall?.copyWith(
                  color: context.palette.warningText,
                ),
              ),
              const SizedBox(height: TicketSurSpacing.sm),
            ],
            // Le ticket tel que l'organisateur l'a dessiné…
            TicketArtwork(
              key: const Key('wallet-artwork'),
              art: t.art,
              template: t.art.templateOfTicket(t.id),
              categoryName: t.categoryName,
              number: t.eventNumber,
              reference: t.reference,
              token: t.status == TicketStatus.issued ? t.token : null,
              holderName: t.holderName,
              invitation: t.isInvitation,
            ),
            // … et son QR en grand, à présenter à l'entrée.
            if (t.status == TicketStatus.issued && t.token != null) ...[
              const SizedBox(height: TicketSurSpacing.md),
              _LargeQr(token: t.token!, reference: t.reference),
            ],
            const SizedBox(height: TicketSurSpacing.md),
            Center(child: walletStatusChip(l10n, t.status)),
            const SizedBox(height: TicketSurSpacing.sm),
            Text(
              switch (t) {
                WalletTicket(
                  status: TicketStatus.redeemed,
                  :final redeemedAt?,
                ) =>
                  l10n.walletUsedAt(_when(redeemedAt)),
                WalletTicket(status: TicketStatus.revoked) =>
                  l10n.walletRevokedNote,
                _ => l10n.walletShowAtEntry,
              },
              key: const Key('wallet-detail-note'),
              textAlign: TextAlign.center,
            ),
            if (t.organizationName.isNotEmpty) ...[
              const SizedBox(height: TicketSurSpacing.xs),
              Text(
                l10n.walletOrganizer(t.organizationName),
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: context.palette.mutedText,
                ),
              ),
            ],
            const SizedBox(height: TicketSurSpacing.lg),
            if (!state.value!.offline)
              TextButton.icon(
                key: const Key('wallet-release'),
                onPressed: () => unawaited(_release(context, ref)),
                icon: const Icon(Icons.remove_circle_outline_rounded),
                label: Text(l10n.walletRelease),
              ),
          ],
        ),
      },
    );
  }
}

/// QR en grand, noir sur blanc, à présenter au contrôleur.
class _LargeQr extends StatelessWidget {
  const new({required this.token, required this.reference});

  final String token;
  final String reference;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(TicketSurRadii.lg),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.sm),
            child: Column(
              children: [
                Text(
                  l10n.walletLargeQr,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: const Color(0xFF111827)),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: BarcodeWidget(
                    key: const Key('ticket-qr'),
                    barcode: Barcode.qrCode(
                      errorCorrectLevel: BarcodeQRCorrectionLevel.medium,
                    ),
                    data: token,
                    backgroundColor: const Color(0xFFFFFFFF),
                    // Marge blanche de 4 modules (33 + 8 modules).
                    padding: const EdgeInsets.all(28),
                  ),
                ),
                Text(
                  reference,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF111827),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
