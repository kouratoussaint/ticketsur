import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/catalog_copy.dart';
import 'package:ticketsur/features/catalog/presentation/event_share.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_cover.dart';
import 'package:ticketsur/features/events/presentation/photo_viewer.dart';
import 'package:ticketsur/features/favorites/presentation/favorite_button.dart';
import 'package:ticketsur/features/profile/presentation/user_avatar.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Fiche publique d'un événement, sans compte.
class PublicEventPage extends ConsumerWidget {
  const new({required this.eventId, super.key});

  final String eventId;

  Future<void> _contact(
    BuildContext context,
    WidgetRef ref,
    PublicEventDetail detail,
  ) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final phone = detail.publicPhone;
    if (phone == null) return;
    final message = l10n.publicEventWhatsAppMessage(
      detail.summary.title,
      summaryWhen(detail.summary),
    );
    final opened = await ref.read(externalLinkProvider)(
      whatsAppUri(phone, message),
    );
    if (!opened) toast.error(l10n.publicEventWhatsAppFailed);
  }

  Future<void> _call(BuildContext context, WidgetRef ref, String phone) async {
    final toast = Toaster.of(context);
    final failed = context.l10n.publicEventCallFailed;
    final opened = await ref.read(externalLinkProvider)(
      Uri(scheme: 'tel', path: phone.replaceAll(RegExp('[^0-9+]'), '')),
    );
    if (!opened) toast.error(failed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(publicEventProvider(eventId));
    return switch (detail) {
      AsyncData(:final value) => _Detail(
        detail: value,
        onContact: () => unawaited(_contact(context, ref, value)),
        onCall: switch (value.publicPhone) {
          final phone? => () => unawaited(_call(context, ref, phone)),
          null => null,
        },
        // Image (statut ou publication) ou texte seul (#18).
        onShare: () => unawaited(showEventShareSheet(context, value)),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_busy_rounded, size: 48),
                const SizedBox(height: TicketSurSpacing.md),
                Text(
                  error == CatalogFailure.notFound
                      ? l10n.publicEventNotFound
                      : error == CatalogFailure.network
                      ? l10n.exploreErrorNetwork
                      : l10n.exploreErrorLoad,
                  key: const Key('public-event-error'),
                  textAlign: TextAlign.center,
                ),
                if (error != CatalogFailure.notFound) ...[
                  const SizedBox(height: TicketSurSpacing.md),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () =>
                        ref.invalidate(publicEventProvider(eventId)),
                    child: Text(l10n.exploreRetry),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _Detail extends ConsumerWidget {
  const new({
    required this.detail,
    required this.onContact,
    required this.onShare,
    this.onCall,
  });

  final PublicEventDetail detail;
  final VoidCallback onContact;
  final VoidCallback onShare;
  final VoidCallback? onCall;

  Future<void> _addToCalendar(BuildContext context, WidgetRef ref) async {
    final failed = context.l10n.publicEventCalendarFailed;
    final toast = Toaster.of(context);
    final event = detail.summary;
    final added = await ref.read(calendarAdderProvider)((
      title: event.title,
      start: event.startsAt,
      end: event.endsAt,
      location: [?event.venue, ?detail.venueAddress, ?event.city].join(', '),
      description: detail.description,
    ));
    if (!added) toast.error(failed);
  }

  Future<void> _directions(BuildContext context, WidgetRef ref) async {
    final failed = context.l10n.publicEventDirectionsFailed;
    final toast = Toaster.of(context);
    final opened = await ref.read(externalLinkProvider)(directionsUri(detail));
    if (!opened) toast.error(failed);
  }

  /// Ouvre l'Explorer filtré (type ou ville de l'événement).
  void _explore(BuildContext context, WidgetRef ref, {EventKind? kind}) {
    final controller = ref.read(catalogQueryProvider.notifier);
    if (kind != null) {
      controller.showKind(kind);
    } else if (detail.summary.city case final city?) {
      controller.showCity(city);
    }
    context.go(AppRoutes.discover);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final tints = context.tints;
    final event = detail.summary;
    final muted = context.palette.mutedText;
    final place = [?event.venue, ?detail.venueAddress, ?event.city];
    final initials = event.organizationName
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: TicketSurColors.navy,
            foregroundColor: TicketSurColors.white,
            actions: [
              FavoriteButton(event: event, color: TicketSurColors.white),
              IconButton(
                key: const Key('public-event-share'),
                tooltip: l10n.publicEventShare,
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                key: const Key('public-event-photo'),
                // Photo en grand, avec téléchargement (#2).
                onTap: switch (event.coverUrl) {
                  final url? => () => unawaited(
                    openEventPhoto(context, url: url, title: event.title),
                  ),
                  null => null,
                },
                behavior: HitTestBehavior.opaque,
                child: EventCover(
                  kind: event.kind,
                  url: event.coverUrl,
                  aspectRatio: 390 / 260,
                  // Haut assombri : boutons blancs lisibles sur toute photo.
                  overlay: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [Color(0x99021A36), Color(0x00021A36)],
                          ),
                        ),
                      ),
                      if (event.coverUrl case final url?)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: PhotoZoomButton(
                            key: const Key('public-event-photo-open'),
                            onPressed: () => unawaited(
                              openEventPhoto(
                                context,
                                url: url,
                                title: event.title,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              TikeoSizes.screenMargin,
              20,
              TikeoSizes.screenMargin,
              TikeoSizes.sectionGap,
            ),
            // Sélection du texte sur le contenu seulement : la photo garde
            // son appui (photo en grand).
            sliver: SliverToBoxAdapter(
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type et ville : ouvrent l'Explorer filtré.
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        GestureDetector(
                          key: const Key('public-event-kind'),
                          onTap: () => _explore(context, ref, kind: event.kind),
                          child: TikeoPill(
                            label: eventKindTag(l10n, event.kind),
                            tint: eventKindTint(event.kind, tints),
                            icon: eventKindIcon(event.kind),
                            uppercase: true,
                          ),
                        ),
                        if (event.city case final city?)
                          GestureDetector(
                            key: const Key('public-event-city'),
                            onTap: () => _explore(context, ref),
                            child: TikeoPill(
                              label: city,
                              tint: tints.salmon,
                              icon: Icons.location_city_rounded,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.title,
                      key: const Key('public-event-title'),
                      style: TikeoTextStyles.heroCardTitle.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (summaryPrice(l10n, event) case final price?) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TikeoPill(
                          label: price,
                          tint: tints.mint,
                          icon: Icons.sell_rounded,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TikeoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _InfoRow(
                            key: const Key('public-event-calendar'),
                            icon: Icons.calendar_month_rounded,
                            tint: tints.mint,
                            title: summaryRange(event),
                            action: l10n.publicEventAddCalendar,
                            onTap: () =>
                                unawaited(_addToCalendar(context, ref)),
                          ),
                          if (place.isNotEmpty) ...[
                            Divider(
                              height: 1,
                              indent: 72,
                              color: theme.colorScheme.outlineVariant,
                            ),
                            _InfoRow(
                              key: const Key('public-event-directions'),
                              icon: Icons.place_rounded,
                              tint: tints.salmon,
                              title: place.first,
                              body: place.length > 1
                                  ? place.skip(1).join(', ')
                                  : null,
                              action: l10n.publicEventDirections,
                              onTap: () => unawaited(_directions(context, ref)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (detail.description case final text?) ...[
                      const SizedBox(height: TikeoSizes.sectionGap - 4),
                      SectionHeader(
                        title: l10n.publicEventAbout,
                        icon: Icons.info_outline_rounded,
                      ),
                      const SizedBox(height: 8),
                      // Tuile blanche, comme les autres blocs (22/11).
                      TikeoCard(
                        key: const Key('public-event-about'),
                        child: Text(text, style: textTheme.bodyLarge),
                      ),
                    ],
                    if (detail.categories.isNotEmpty) ...[
                      const SizedBox(height: TikeoSizes.sectionGap - 4),
                      SectionHeader(
                        title: l10n.publicEventTickets,
                        icon: Icons.confirmation_number_rounded,
                      ),
                      const SizedBox(height: 8),
                      for (final category in detail.categories)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CategoryRow(
                            name: category.name,
                            price: category.price,
                          ),
                        ),
                    ],
                    const SizedBox(height: TikeoSizes.sectionGap - 4),
                    TikeoCard(
                      key: const Key('public-event-organizer'),
                      padding: EdgeInsets.zero,
                      // Appui : page publique de la structure (22/11).
                      child: InkWell(
                        borderRadius: BorderRadius.circular(TikeoRadii.card),
                        onTap: switch (detail.organizationId) {
                          final id? => () => unawaited(
                            context.push(AppRoutes.publicOrganization(id)),
                          ),
                          null => null,
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              UserAvatar(
                                initials: initials,
                                url: detail.organizationLogoUrl,
                                radius: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.publicEventOrganizer,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: muted,
                                      ),
                                    ),
                                    Text(
                                      event.organizationName,
                                      style: textTheme.titleMedium,
                                    ),
                                    if (detail.organizationId != null)
                                      Text(
                                        l10n.publicOrgSeeAll,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: context.palette.accentText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (detail.organizationId != null)
                                Icon(Icons.chevron_right_rounded, color: muted),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (detail.organizationId case final organizationId?)
                      _SameOrganizer(
                        organizationId: organizationId,
                        currentId: event.id,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          boxShadow: TikeoShadows.cardFor(theme.brightness),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TikeoSizes.screenMargin,
              12,
              TikeoSizes.screenMargin,
              12,
            ),
            child: detail.publicPhone == null
                ? Text(
                    l10n.publicEventNoContact,
                    key: const Key('public-event-no-contact'),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: muted),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TikeoPrimaryButton(
                          key: const Key('public-event-whatsapp'),
                          label: l10n.publicEventGetTicket,
                          icon: Icons.chat_rounded,
                          onPressed: onContact,
                        ),
                      ),
                      if (onCall != null) ...[
                        const SizedBox(width: 8),
                        TikeoSquareButton(
                          key: const Key('public-event-call'),
                          icon: Icons.call_rounded,
                          tooltip: l10n.publicEventCall,
                          onPressed: onCall,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Ligne d'information : rond pastel avec icône, titre et détail.
class _InfoRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.tint,
    required this.title,
    this.body,
    this.onTap,
    this.action,
    super.key,
  });

  final IconData icon;
  final TikeoTint tint;
  final String title;
  final String? body;

  /// Appui sur la ligne (agenda, itinéraire).
  final VoidCallback? onTap;

  /// Libellé de l'action, avec une flèche, à droite.
  final String? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final row = Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: TikeoSizes.settingsIconCircle,
            height: TikeoSizes.settingsIconCircle,
            decoration: BoxDecoration(
              color: tint.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: tint.icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                if (body case final text?)
                  Text(
                    text,
                    style: textTheme.bodySmall?.copyWith(
                      color: context.palette.mutedText,
                    ),
                  ),
                if (action case final label?)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: textTheme.labelMedium?.copyWith(
                        color: context.palette.accentText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, color: context.palette.mutedText),
        ],
      ),
    );
    return onTap == null
        ? row
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TikeoRadii.card),
            child: row,
          );
  }
}

/// Catégorie de ticket : VIP doré, les autres en gris ; prix en pastille
/// menthe, « Prix auprès du promoteur » en texte discret.
class _CategoryRow extends StatelessWidget {
  const new({required this.name, required this.price});

  final String name;
  final int? price;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final vip = name.toUpperCase().contains('VIP');
    final tint = vip ? tints.vip : tints.gray;
    return TikeoCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.background,
              borderRadius: BorderRadius.circular(TikeoRadii.thumb),
            ),
            child: Icon(
              vip
                  ? Icons.workspace_premium_rounded
                  : Icons.confirmation_number_rounded,
              color: vip ? tint.icon : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: theme.textTheme.titleSmall)),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: switch (price) {
              null => Text(
                l10n.publicEventPriceUnknown,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.palette.mutedText,
                ),
              ),
              0 => TikeoPill(label: l10n.exploreFree, tint: tints.mint),
              final amount => TikeoPill(
                label: formatFcfa(l10n, amount),
                tint: tints.mint,
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// « Du même organisateur » : jusqu'à 3 autres événements à venir de la
/// structure, et « Tout voir » vers sa page. Rien en cas d'échec.
class _SameOrganizer extends ConsumerWidget {
  const new({required this.organizationId, required this.currentId});

  final String organizationId;
  final String currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final others = [
      for (final event
          in ref
                  .watch(publicOrganizationProvider(organizationId))
                  .value
                  ?.events ??
              const <PublicEventSummary>[])
        if (event.id != currentId) event,
    ];
    if (others.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('public-event-same-org'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: TikeoSizes.sectionGap - 4),
        SectionHeader(
          title: l10n.publicEventSameOrganizer,
          icon: Icons.storefront_rounded,
          actionLabel: others.length > 3
              ? l10n.publicEventSeeAllOrganizer
              : null,
          actionKey: const Key('public-event-same-org-all'),
          onAction: () => unawaited(
            context.push(AppRoutes.publicOrganization(organizationId)),
          ),
        ),
        const SizedBox(height: 8),
        for (final event in others.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PublicEventTile(event: event),
          ),
      ],
    );
  }
}
