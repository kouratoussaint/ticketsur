import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/empty_state.dart';
import 'package:ticketsur/design_system/widgets/status_chip.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/search/application/search_providers.dart';
import 'package:ticketsur/features/search/domain/search.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Recherche globale du promoteur (lot 4-6b) : événements de la structure,
/// tickets de tous ses événements par nom, téléphone ou référence.
class SearchPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _field = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searching = _query.length >= minSearchLength;
    final results = searching
        ? ref.watch(promoterSearchProvider(_query))
        : null;
    const margin = EdgeInsets.symmetric(horizontal: TikeoSizes.screenMargin);
    return Scaffold(
      body: ListView(
        key: const Key('search-list'),
        padding: const EdgeInsets.only(bottom: TikeoSizes.sectionGap),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TikeoHeroHeader(
                title: l10n.searchTitle,
                subtitle: l10n.searchSubtitle,
                onBack: () => context.popOr(AppRoutes.home),
              ),
              TikeoOverlapCard(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  key: const Key('search-field'),
                  controller: _field,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: l10n.searchHint,
                    suffixIcon: _field.text.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('search-clear'),
                            tooltip: l10n.searchClear,
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _field.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (text) {
                    setState(() {});
                    _onChanged(text);
                  },
                  onSubmitted: (text) {
                    _debounce?.cancel();
                    setState(() => _query = text.trim());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: TikeoSizes.cardGap),
          ...switch (results) {
            null => [
              Padding(
                padding: margin,
                child: EmptyState(
                  icon: Icons.search_rounded,
                  illustration: TikeoIllustration.noResults,
                  title: l10n.searchIdleTitle,
                  titleKey: const Key('search-idle'),
                  body: l10n.searchIdleBody,
                ),
              ),
            ],
            AsyncValue(:final value?) when value.isEmpty => [
              Padding(
                padding: margin,
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  illustration: TikeoIllustration.noResults,
                  title: l10n.searchNoResult(_query),
                  titleKey: const Key('search-empty'),
                  body: l10n.searchNoResultBody,
                ),
              ),
            ],
            AsyncValue(:final value?) => [
              if (value.events.isNotEmpty) ...[
                Padding(
                  padding: margin,
                  child: SectionHeader(
                    key: const Key('search-events'),
                    title: l10n.searchEvents(value.events.length),
                    icon: Icons.event_rounded,
                  ),
                ),
                for (final event in value.events)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TikeoSizes.screenMargin,
                      0,
                      TikeoSizes.screenMargin,
                      8,
                    ),
                    child: _EventHit(event: event),
                  ),
                const SizedBox(height: TikeoSizes.cardGap),
              ],
              if (value.tickets.isNotEmpty) ...[
                Padding(
                  padding: margin,
                  child: SectionHeader(
                    key: const Key('search-tickets'),
                    title: l10n.searchTickets(value.tickets.length),
                    icon: Icons.confirmation_number_rounded,
                  ),
                ),
                for (final ticket in value.tickets)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TikeoSizes.screenMargin,
                      0,
                      TikeoSizes.screenMargin,
                      8,
                    ),
                    child: _TicketHit(ticket: ticket),
                  ),
              ],
            ],
            AsyncValue(:final error?) => [
              Padding(
                padding: margin,
                child: Text(
                  error == SearchFailure.network
                      ? l10n.searchErrorNetwork
                      : l10n.searchError,
                  key: const Key('search-error'),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            _ => const [
              Padding(
                padding: EdgeInsets.all(TikeoSizes.screenMargin),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
        ],
      ),
    );
  }
}

class _EventHit extends StatelessWidget {
  const new({required this.event});

  final SearchEventHit event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tint = eventKindTint(event.kind, context.tints);
    return TikeoListRow(
      key: Key('search-event-${event.id}'),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: tint.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(eventKindIcon(event.kind), color: tint.icon),
      ),
      title: event.title,
      lines: [
        formatDateAtTime(event.startsAt.toLocal()),
        if ([event.venue, event.city].nonNulls.join(' · ') case final place
            when place.isNotEmpty)
          place,
      ],
      badge: StatusChip(
        label: eventStatusLabel(l10n, event.status),
        tone: StatusTone.neutral,
      ),
      onTap: () => unawaited(context.push(AppRoutes.eventDetail(event.id))),
    );
  }
}

class _TicketHit extends StatelessWidget {
  const new({required this.ticket});

  final SearchTicketHit ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    final tint = ticketStatusTint(ticket.status, tints);
    final style = ticketStatusStyle(ticket.status, tints);
    return TikeoListRow(
      key: Key('search-ticket-${ticket.id}'),
      stripe: tint.icon,
      title: ticket.holderName ?? ticket.reference,
      lines: [
        [
          if (ticket.holderName != null) ticket.reference,
          ticket.category,
          ?ticket.holderPhone,
        ].join(' · '),
        ticket.eventTitle,
      ],
      badge: StatusChip(
        label: ticketStatusLabel(l10n, ticket.status),
        tone: StatusTone.neutral,
        tint: tint,
        icon: style.icon,
      ),
      onTap: () => unawaited(
        context.push(AppRoutes.ticketDetail(ticket.eventId, ticket.id)),
      ),
    );
  }
}
