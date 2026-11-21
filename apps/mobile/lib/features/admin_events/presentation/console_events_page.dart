import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/admin_events/application/admin_events_providers.dart';
import 'package:ticketsur/features/admin_events/domain/admin_events.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _day(DateTime instant) =>
    DateFormat.yMMMd(appLocaleTag).format(instant.toLocal());

/// Console : tous les événements de la plateforme (lot 4-11c).
class ConsoleEventsPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleEventsPage> createState() => _ConsoleEventsPageState();
}

class _ConsoleEventsPageState extends ConsumerState<ConsoleEventsPage> {
  String _search = '';
  EventStatus? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ref.watch(adminEventsRepositoryProvider);
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.consoleNavEvents)),
      body: ConsolePagedList<AdminEventRow>(
        key: ValueKey(('events', _search, _status)),
        load: (offset, _) =>
            repository.events(search: _search, status: _status, offset: offset),
        header: Padding(
          padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConsoleSearchField(
                key: const Key('console-event-search'),
                hint: l10n.adminEventsSearch,
                initial: _search,
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              Wrap(
                spacing: TicketSurSpacing.xs,
                runSpacing: TicketSurSpacing.xs,
                children: [
                  ChoiceChip(
                    key: const Key('console-events-all'),
                    label: Text(l10n.adminEventsAll),
                    selected: _status == null,
                    onSelected: (_) => setState(() => _status = null),
                  ),
                  for (final status in EventStatus.values)
                    ChoiceChip(
                      key: Key('console-events-${status.wireName}'),
                      label: Text(eventStatusLabel(l10n, status)),
                      selected: _status == status,
                      onSelected: (_) => setState(() => _status = status),
                    ),
                ],
              ),
            ],
          ),
        ),
        itemBuilder: (context, event, reload) => _EventTile(
          event: event,
          onOpen: () async {
            await context.push(AppRoutes.consoleEvent(event.id));
            reload();
          },
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const new({required this.event, required this.onOpen});

  final AdminEventRow event;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.palette.mutedText);
    return Card(
      key: Key('console-event-${event.id}'),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ConsoleTag(
                    label: eventStatusLabel(l10n, event.status),
                    danger: event.status == EventStatus.cancelled,
                  ),
                ],
              ),
              Text(
                [
                  event.organizationName,
                  _day(event.startsAt),
                  ?event.city,
                ].join(' · '),
                style: muted,
              ),
              Text(
                l10n.adminOrgsEventTickets(event.tickets, event.admitted),
                style: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
