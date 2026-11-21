import 'dart:async';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/status_chip.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_cover.dart';
import 'package:ticketsur/features/scanner/presentation/camera/scan_camera.dart';
import 'package:ticketsur/features/ticket_templates/presentation/ticket_artwork.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
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
    final value = wallet.value;
    final tickets = wallet is AsyncData ? value?.tickets ?? const [] : null;
    final withSummary = tickets != null && tickets.isNotEmpty;
    final header = TikeoHeroHeader(
      title: l10n.walletTitle,
      subtitle: l10n.walletHeroSubtitle,
      illustration: TikeoIllustration.wallet,
      onBack: showBack ? () => context.popOr(AppRoutes.profile) : null,
      overlap: withSummary ? TikeoSizes.heroOverlap : 0,
    );
    final content = switch (wallet) {
      AsyncData(value: WalletState(:final tickets)) when tickets.isEmpty => [
        const SizedBox(height: 16),
        const TikeoIllustrationView(TikeoIllustration.noTickets),
        const SizedBox(height: 16),
        Text(
          l10n.walletEmptyTitle,
          key: const Key('wallet-empty'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.walletEmptyBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        TikeoPrimaryButton(
          key: const Key('wallet-empty-add'),
          onPressed: add,
          icon: Icons.add_rounded,
          label: l10n.walletAdd,
        ),
      ],
      AsyncData(:final value) => [
        if (value.savedAt case final saved?) ...[
          const SizedBox(height: TikeoSizes.cardGap),
          TintedBanner(
            key: const Key('wallet-offline'),
            tint: context.tints.amber,
            icon: Icons.cloud_off_rounded,
            title: l10n.walletOffline(_when(saved)),
          ),
        ],
        for (final (title, past) in [
          (l10n.walletUpcoming, false),
          (l10n.walletPast, true),
        ])
          if (value.tickets.any((t) => t.isPastAt(now) == past)) ...[
            const SizedBox(height: TikeoSizes.cardGap),
            SectionHeader(
              title: title,
              icon: past ? Icons.history_rounded : Icons.event_rounded,
            ),
            const SizedBox(height: 8),
            for (final ticket in value.tickets)
              if (ticket.isPastAt(now) == past)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _WalletTile(ticket: ticket),
                ),
          ],
      ],
      AsyncError(:final error) => [
        const SizedBox(height: 16),
        const TikeoIllustrationView(TikeoIllustration.offline),
        const SizedBox(height: 16),
        Text(
          error == WalletFailure.network
              ? l10n.walletErrorNetwork
              : l10n.walletLoadError,
          key: const Key('wallet-error'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => ref.invalidate(walletProvider),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.walletRetry),
        ),
      ],
      _ => [
        const SizedBox(height: TikeoSizes.cardGap),
        Shimmer(
          child: Column(
            children: [
              for (var i = 0; i < 3; i++)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SkeletonBox(height: 96, radius: 16),
                ),
            ],
          ),
        ),
      ],
    };
    return Scaffold(
      floatingActionButton: withSummary
          ? FloatingActionButton.extended(
              key: const Key('wallet-add'),
              heroTag: 'wallet-add',
              onPressed: add,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.walletAdd),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.read(walletProvider.notifier).reload();
          } on Object {
            // L'échec s'affiche dans la page.
          }
        },
        child: ListView(
          key: withSummary ? const Key('wallet-list') : null,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                if (withSummary)
                  TikeoOverlapCard(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _Summary(tickets: tickets, now: now),
                  ),
              ],
            ),
            for (final child in content)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TikeoSizes.screenMargin,
                ),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}

/// À venir, valables, passés.
class _Summary extends StatelessWidget {
  const new({required this.tickets, required this.now});

  final List<WalletTicket> tickets;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    return StatStrip(
      key: const Key('wallet-summary'),
      centered: true,
      items: [
        (
          value: '${tickets.where((t) => !t.isPastAt(now)).length}',
          label: l10n.walletSummaryUpcoming,
          color: tints.mint.text,
        ),
        (
          value:
              '${tickets.where((t) => t.status == TicketStatus.issued).length}',
          label: l10n.walletSummaryValid,
          color: tints.blue.text,
        ),
        (
          value: '${tickets.where((t) => t.isPastAt(now)).length}',
          label: l10n.walletSummaryPast,
          color: tints.gray.text,
        ),
      ],
    );
  }
}

class _WalletTile extends StatelessWidget {
  const new({required this.ticket});

  final WalletTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final event = ticket.event;
    final tints = context.tints;
    final vip = ticket.categoryName.toUpperCase().contains('VIP');
    return TikeoListRow(
      key: Key('wallet-ticket-${ticket.id}'),
      stripe: ticketStatusTint(ticket.status, tints).icon,
      leading: SizedBox(
        width: 72,
        height: 72,
        child: EventCover.forEvent(
          event,
          aspectRatio: 1,
          borderRadius: BorderRadius.circular(TikeoRadii.thumb),
        ),
      ),
      title: event.title,
      lines: [formatEventRange(event), ?(event.venue ?? event.city)],
      badge: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          walletStatusChip(l10n, ticket.status),
          TikeoPill(
            label: ticket.categoryName,
            tint: vip ? tints.vip : tints.gray,
            icon: vip
                ? Icons.workspace_premium_rounded
                : Icons.confirmation_number_rounded,
          ),
        ],
      ),
      onTap: () => unawaited(context.push(AppRoutes.walletTicket(ticket.id))),
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
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SettingsRow(
        key: key,
        icon: icon,
        tint: context.tints.mint,
        title: title,
        subtitle: hint,
        onTap: _busy ? null : onTap,
      ),
    );
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
        ),
        children: [
          TikeoHeroHeader(
            title: l10n.walletAddTitle,
            subtitle: l10n.walletAddIntro,
            illustration: TikeoIllustration.tickets,
            onBack: () => context.popOr(AppRoutes.walletTab),
            overlap: 0,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TikeoSizes.screenMargin,
              TikeoSizes.cardGap,
              TikeoSizes.screenMargin,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _addContent(context, theme, option),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _addContent(
    BuildContext context,
    ThemeData theme,
    Widget Function({
      required Key key,
      required IconData icon,
      required String title,
      required String hint,
      required VoidCallback onTap,
    })
    option,
  ) {
    final l10n = context.l10n;
    return [
      if (_error case final error?) ...[
        TintedBanner(
          key: const Key('wallet-add-error'),
          tint: context.tints.red,
          icon: Icons.error_rounded,
          title: error,
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
      TikeoPrimaryButton(
        key: const Key('wallet-add-submit'),
        busy: _busy,
        onPressed: _busy ? null : () => unawaited(_claim(_code.text)),
        icon: Icons.add_card_rounded,
        label: l10n.walletAddPasteSubmit,
      ),
    ];
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
    final header = TikeoHeroHeader(
      title: ticket?.event.title ?? l10n.walletTitle,
      subtitle: ticket == null ? null : l10n.walletTitle,
      onBack: () => context.popOr(AppRoutes.walletTab),
      overlap: 0,
    );
    final tints = context.tints;
    return Scaffold(
      body: switch (ticket) {
        null when state.isLoading => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
        null => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(
              child: Center(
                child: Text(
                  l10n.walletNotFound,
                  key: const Key('wallet-not-found'),
                ),
              ),
            ),
          ],
        ),
        final t => SelectionArea(
          child: ListView(
            key: Key('wallet-detail-${t.id}'),
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
            ),
            children: [
              header,
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TikeoSizes.screenMargin,
                  TikeoSizes.cardGap,
                  TikeoSizes.screenMargin,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    TintedBanner(
                      tint: ticketStatusTint(t.status, tints),
                      icon: switch (t.status) {
                        TicketStatus.issued => Icons.check_circle_rounded,
                        TicketStatus.redeemed => Icons.verified_rounded,
                        TicketStatus.revoked => Icons.cancel_rounded,
                        TicketStatus.expired => Icons.hourglass_empty_rounded,
                      },
                      title: walletStatusChip(l10n, t.status).label,
                      body: switch (t) {
                        WalletTicket(
                          status: TicketStatus.redeemed,
                          :final redeemedAt?,
                        ) =>
                          l10n.walletUsedAt(_when(redeemedAt)),
                        WalletTicket(status: TicketStatus.revoked) =>
                          l10n.walletRevokedNote,
                        _ => l10n.walletShowAtEntry,
                      },
                      bodyKey: const Key('wallet-detail-note'),
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
                      TikeoDangerButton(
                        key: const Key('wallet-release'),
                        onPressed: () => unawaited(_release(context, ref)),
                        icon: Icons.remove_circle_rounded,
                        label: l10n.walletRelease,
                      ),
                  ],
                ),
              ),
            ],
          ),
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
