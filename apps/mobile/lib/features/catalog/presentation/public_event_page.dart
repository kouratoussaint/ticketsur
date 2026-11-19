import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/catalog_copy.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/events/presentation/event_cover.dart';
import 'package:ticketsur/features/team/application/team_providers.dart'
    show shareTextProvider;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(publicEventProvider(eventId));
    return switch (detail) {
      AsyncData(:final value) => _Detail(
        detail: value,
        onContact: () => unawaited(_contact(context, ref, value)),
        onShare: () => unawaited(
          ref.read(shareTextProvider)(
            l10n.publicEventShareText(
              value.summary.title,
              summaryWhen(value.summary),
              summaryPlace(value.summary),
            ),
          ),
        ),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_busy_outlined, size: 48),
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

class _Detail extends StatelessWidget {
  const new({
    required this.detail,
    required this.onContact,
    required this.onShare,
  });

  final PublicEventDetail detail;
  final VoidCallback onContact;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final event = detail.summary;
    final muted = context.palette.mutedText;
    Widget infoRow(IconData icon, Color tint, String title, String? body) =>
        Padding(
          padding: const EdgeInsets.all(TicketSurSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(TicketSurRadii.sm),
                ),
                child: Icon(icon, color: TicketSurColors.navy),
              ),
              const SizedBox(width: TicketSurSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    if (body != null)
                      Text(
                        body,
                        style: textTheme.bodySmall?.copyWith(color: muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
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
            expandedHeight: 240,
            backgroundColor: TicketSurColors.navy,
            foregroundColor: TicketSurColors.white,
            actions: [
              IconButton(
                key: const Key('public-event-share'),
                tooltip: l10n.publicEventShare,
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: EventCover(
                kind: event.kind,
                url: event.coverUrl,
                aspectRatio: 390 / 240,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              TicketSurSpacing.md,
              TicketSurSpacing.md,
              TicketSurSpacing.md,
              TicketSurSpacing.xl,
            ),
            sliver: SliverList.list(
              children: [
                Text(
                  exploreKindTag(l10n, event.kind),
                  style: textTheme.labelMedium?.copyWith(
                    color: context.palette.accentText,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.xxs),
                Text(
                  event.title,
                  key: const Key('public-event-title'),
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: TicketSurSpacing.md),
                Card(
                  margin: EdgeInsets.zero,
                  color: scheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TicketSurRadii.md),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      infoRow(
                        Icons.calendar_month_outlined,
                        const Color(0xFFCFF6EE),
                        summaryRange(event),
                        null,
                      ),
                      if (place.isNotEmpty) ...[
                        Divider(height: 1, color: scheme.outlineVariant),
                        infoRow(
                          Icons.place_outlined,
                          const Color(0xFFFFE3D8),
                          place.first,
                          place.length > 1 ? place.skip(1).join(', ') : null,
                        ),
                      ],
                    ],
                  ),
                ),
                if (detail.description case final text?) ...[
                  const SizedBox(height: TicketSurSpacing.lg),
                  Text(l10n.publicEventAbout, style: textTheme.titleLarge),
                  const SizedBox(height: TicketSurSpacing.xs),
                  Text(text, style: textTheme.bodyLarge),
                ],
                if (detail.categories.isNotEmpty) ...[
                  const SizedBox(height: TicketSurSpacing.lg),
                  Text(l10n.publicEventTickets, style: textTheme.titleLarge),
                  const SizedBox(height: TicketSurSpacing.xs),
                  for (final category in detail.categories)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: TicketSurSpacing.xs,
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: scheme.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            TicketSurRadii.md,
                          ),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TicketSurSpacing.md,
                            vertical: TicketSurSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: textTheme.bodyLarge,
                                ),
                              ),
                              const SizedBox(width: TicketSurSpacing.sm),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 170,
                                ),
                                child: Text(
                                  switch (category.price) {
                                    null => l10n.publicEventPriceUnknown,
                                    0 => l10n.exploreFree,
                                    final price => formatFcfa(l10n, price),
                                  },
                                  textAlign: TextAlign.end,
                                  style: category.price == null
                                      ? textTheme.bodySmall?.copyWith(
                                          color: muted,
                                        )
                                      : textTheme.titleSmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: TicketSurSpacing.lg),
                Card(
                  margin: EdgeInsets.zero,
                  color: scheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TicketSurRadii.md),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: TicketSurColors.navy,
                      foregroundColor: TicketSurColors.white,
                      child: Text(initials),
                    ),
                    title: Text(
                      l10n.publicEventOrganizer,
                      style: textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    subtitle: Text(
                      event.organizationName,
                      style: textTheme.titleSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TicketSurSpacing.md,
            TicketSurSpacing.xs,
            TicketSurSpacing.md,
            TicketSurSpacing.sm,
          ),
          child: detail.publicPhone == null
              ? Text(
                  l10n.publicEventNoContact,
                  key: const Key('public-event-no-contact'),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: muted),
                )
              : FilledButton.icon(
                  key: const Key('public-event-whatsapp'),
                  onPressed: onContact,
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(l10n.publicEventGetTicket),
                ),
        ),
      ),
    );
  }
}
