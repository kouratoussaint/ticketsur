import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/audit_labels.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/features/admin_events/application/admin_events_providers.dart';
import 'package:ticketsur/features/admin_events/domain/admin_events.dart';
import 'package:ticketsur/features/admin_orgs/application/admin_orgs_providers.dart';
import 'package:ticketsur/features/admin_tools/domain/admin_tools.dart';
import 'package:ticketsur/features/admin_tools/presentation/console_shortcuts.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _day(DateTime instant) =>
    DateFormat.yMMMd(appLocaleTag).format(instant.toLocal());

String _when(DateTime instant) => formatDateAtTime(instant.toLocal());

/// Heure murale de l'événement, lisible (« 24 déc. 2026 à 20:00 »).
String _wall(String zone, DateTime instant) =>
    formatDateAtTime(wallTimeIn(zone, instant));

/// Console : fiche d'un événement et actions (lot 4-11c, ADR 0040).
class AdminEventDetailPage extends ConsumerWidget {
  const new({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(adminEventDetailProvider(eventId));
    return Scaffold(
      appBar: TikeoAppBar(
        title: Text(detail.value?.title ?? l10n.adminEventsTitle),
      ),
      body: switch (detail) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(adminEventDetailProvider(eventId).future),
          child: _Detail(event: value),
        ),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  adminAccountsFailureMessage(l10n, error),
                  key: const Key('event-admin-error'),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(adminEventDetailProvider(eventId)),
                  child: Text(l10n.consoleRetry),
                ),
              ],
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Detail extends ConsumerWidget {
  const new({required this.event});

  final AdminEventDetail event;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<String?> Function() action,
  ) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    try {
      final message = await action();
      if (message != null) toast.success(message);
      ref
        ..invalidate(adminEventDetailProvider(event.id))
        ..invalidate(adminOverviewProvider)
        ..invalidate(consoleTrashProvider);
    } on Object catch (error) {
      toast.error(adminAccountsFailureMessage(l10n, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(adminMeProvider).value;
    final repository = ref.read(adminEventsRepositoryProvider);
    final notify = me?.notifyUsers ?? false;
    final canEvents = me?.can(AdminPermission.events) ?? false;
    final canIssue =
        (me?.can(AdminPermission.tickets) ?? false) &&
        (me?.adminIssueTickets ?? false) &&
        !event.trashed &&
        (event.status == EventStatus.published ||
            event.status == EventStatus.inProgress) &&
        event.categories.isNotEmpty;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );
    final base = AdminEventEdit.of(event);

    Future<void> save(AdminEventEdit edit, ActionSheetResult result) =>
        _run(context, ref, () async {
          await repository.updateEvent(
            event.id,
            edit,
            reason: result.reason,
            notify: result.notify,
          );
          return l10n.adminEventsUpdated;
        });

    Future<void> edit() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminEventsEdit,
        confirmLabel: l10n.profileSave,
        notifyDefault: notify,
        fields: [
          ActionField(
            name: 'title',
            label: l10n.adminEventsFieldTitle,
            initial: event.title,
            validator: (value) => value.length < 2 || value.length > 160
                ? l10n.adminEventsErrorFields
                : null,
          ),
          ActionField(
            name: 'venue',
            label: l10n.adminEventsFieldVenue,
            initial: event.venue,
            required: false,
          ),
          ActionField(
            name: 'city',
            label: l10n.adminOrgsCity,
            initial: event.city,
            required: false,
          ),
          ActionField(
            name: 'address',
            label: l10n.adminEventsFieldAddress,
            initial: event.venueAddress,
            required: false,
          ),
          ActionField(
            name: 'tagline',
            label: l10n.adminEventsFieldTagline,
            initial: event.tagline,
            required: false,
            validator: (value) =>
                value.length > 60 ? l10n.adminEventsErrorTagline : null,
          ),
          ActionField(
            name: 'description',
            label: l10n.adminEventsFieldDescription,
            initial: event.description,
            required: false,
          ),
          ActionField(
            name: 'capacity',
            label: l10n.adminEventsFieldCapacity,
            initial: event.capacity?.toString(),
            keyboard: TextInputType.number,
            required: false,
            validator: (value) => (int.tryParse(value) ?? 0) < 1
                ? l10n.adminEventsErrorFields
                : null,
          ),
        ],
      );
      if (result == null || !context.mounted) return;
      String? optional(String key) =>
          result.fields[key]!.isEmpty ? null : result.fields[key];
      await save(
        base.copyWith(
          title: result.fields['title'],
          venue: () => optional('venue'),
          city: () => optional('city'),
          venueAddress: () => optional('address'),
          tagline: () => optional('tagline'),
          description: () => optional('description'),
          capacity: () => int.tryParse(result.fields['capacity']!),
        ),
        result,
      );
    }

    Future<void> changeDates() async {
      final dates = await showModalBottomSheet<(DateTime, DateTime)>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _DatesSheet(event: event),
      );
      if (dates == null || !context.mounted) return;
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminEventsDates,
        body:
            '${_wall(event.timezone, dates.$1)} → '
            '${_wall(event.timezone, dates.$2)}',
        confirmLabel: l10n.profileSave,
        notifyDefault: notify,
      );
      if (result == null || !context.mounted) return;
      await save(base.copyWith(startsAt: dates.$1, endsAt: dates.$2), result);
    }

    Future<void> togglePublic() async {
      final result = await showAccountActionSheet(
        context,
        title: event.isPublic
            ? l10n.adminEventsMakePrivate
            : l10n.adminEventsMakePublic,
        confirmLabel: l10n.profileSave,
        notifyDefault: notify,
      );
      if (result == null || !context.mounted) return;
      await save(base.copyWith(isPublic: !event.isPublic), result);
    }

    Future<void> setStatus(EventStatus target) async {
      final cancel = target == EventStatus.cancelled;
      final body = [
        eventConfirmBody(l10n, target, event.status),
        if (cancel) ...[
          l10n.adminOrgsPreviewTickets(event.ticketsToCancel),
          l10n.adminOrgsPreviewHolders(event.holdersToNotify),
        ],
      ].join('\n');
      final result = await showAccountActionSheet(
        context,
        title: eventActionLabel(l10n, target, event.status),
        body: body,
        confirmLabel: eventActionLabel(l10n, target, event.status),
        notifyDefault: notify,
        destructive: cancel,
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        final outcome = await repository.setStatus(
          event.id,
          target,
          reason: result.reason,
          notify: result.notify,
        );
        return cancel
            ? l10n.adminEventsCancelled(outcome.ticketsCancelled)
            : l10n.adminEventsStatusChanged(eventStatusLabel(l10n, target));
      });
    }

    Future<void> move() async {
      final organization = await showModalBottomSheet<AdminOrganization>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) =>
            _OrganizationPicker(excludeId: event.organizationId),
      );
      if (organization == null || !context.mounted) return;
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminEventsMove,
        body: l10n.adminEventsMoveHint(organization.name),
        confirmLabel: l10n.adminEventsMove,
        notifyDefault: notify,
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        await repository.move(
          event.id,
          organization.id,
          reason: result.reason,
          notify: result.notify,
        );
        return l10n.adminEventsMoved;
      });
    }

    Future<void> trash() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminEventsTrash,
        body: l10n.adminEventsTrashHint,
        confirmLabel: l10n.adminEventsTrash,
        notifyDefault: notify,
        destructive: true,
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        await repository.trash(
          event.id,
          reason: result.reason,
          notify: result.notify,
        );
        return l10n.adminEventsTrashed;
      });
    }

    Future<void> restore() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminOrgsRestore,
        confirmLabel: l10n.adminOrgsRestore,
        notifyDefault: notify,
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        await repository.restore(
          event.id,
          reason: result.reason,
          notify: result.notify,
        );
        return l10n.adminEventsRestored;
      });
    }

    Future<void> issue() async {
      final request = await showModalBottomSheet<(String, int, String)>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _IssueSheet(event: event),
      );
      if (request == null || !context.mounted) return;
      final (categoryId, quantity, reason) = request;
      await _run(context, ref, () async {
        final count = await repository.issueTickets(
          event.id,
          categoryId: categoryId,
          quantity: quantity,
          reason: reason,
        );
        return l10n.adminEventsIssued(count);
      });
    }

    final actions = <Widget>[
      ...consoleFicheShortcuts(
        context,
        ref,
        target: MessageTarget(
          kind: MessageTargetKind.event,
          id: event.id,
          name: event.title,
        ),
        journal: AuditScope(eventId: event.id, label: event.title),
        canMessage: !event.trashed,
        keyPrefix: 'event-admin',
      ),
      if (canEvents && event.editable) ...[
        OutlinedButton.icon(
          key: const Key('event-admin-edit'),
          onPressed: () => unawaited(edit()),
          icon: const Icon(Icons.edit_rounded),
          label: Text(l10n.adminEventsEdit),
        ),
        OutlinedButton.icon(
          key: const Key('event-admin-dates'),
          onPressed: () => unawaited(changeDates()),
          icon: const Icon(Icons.event_rounded),
          label: Text(l10n.adminEventsDates),
        ),
        OutlinedButton.icon(
          key: const Key('event-admin-public'),
          onPressed: () => unawaited(togglePublic()),
          icon: Icon(
            event.isPublic ? Icons.lock_rounded : Icons.public_rounded,
          ),
          label: Text(
            event.isPublic
                ? l10n.adminEventsMakePrivate
                : l10n.adminEventsMakePublic,
          ),
        ),
      ],
      if (canEvents && !event.trashed)
        for (final target in event.nextStatuses)
          OutlinedButton.icon(
            key: Key('event-admin-status-${target.wireName}'),
            style: target == EventStatus.cancelled
                ? OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: () => unawaited(setStatus(target)),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(eventActionLabel(l10n, target, event.status)),
          ),
      if (canEvents && !event.trashed && !event.hasInvoice)
        OutlinedButton.icon(
          key: const Key('event-admin-move'),
          onPressed: () => unawaited(move()),
          icon: const Icon(Icons.drive_file_move_rounded),
          label: Text(l10n.adminEventsMove),
        ),
      if (canIssue)
        OutlinedButton.icon(
          key: const Key('event-admin-issue'),
          onPressed: () => unawaited(issue()),
          icon: const Icon(Icons.confirmation_number_rounded),
          label: Text(l10n.adminEventsIssue),
        ),
      if (canEvents && event.trashable)
        FilledButton.icon(
          key: const Key('event-admin-trash'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => unawaited(trash()),
          icon: const Icon(Icons.delete_rounded),
          label: Text(l10n.adminEventsTrash),
        ),
      if (canEvents && event.trashed)
        FilledButton.icon(
          key: const Key('event-admin-restore'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => unawaited(restore()),
          icon: const Icon(Icons.restore_from_trash_rounded),
          label: Text(l10n.adminOrgsRestore),
        ),
    ];

    return SingleChildScrollView(
      key: const Key('event-admin-detail'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TikeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(event.title, style: textTheme.titleLarge),
                if (event.tagline case final tagline?) Text(tagline),
                const SizedBox(height: TicketSurSpacing.xs),
                Wrap(
                  spacing: TicketSurSpacing.xxs,
                  runSpacing: TicketSurSpacing.xxs,
                  children: [
                    ConsoleTag(
                      key: const Key('event-admin-status'),
                      label: eventStatusLabel(l10n, event.status),
                      danger: event.status == EventStatus.cancelled,
                    ),
                    ConsoleTag(
                      label: event.isPublic
                          ? l10n.adminEventsPublic
                          : l10n.adminEventsPrivate,
                      danger: false,
                    ),
                    if (event.blocked)
                      ConsoleTag(label: l10n.adminEventsBlocked, danger: true),
                    if (event.trashed)
                      ConsoleTag(
                        key: const Key('event-admin-trashed'),
                        label: l10n.adminOrgsTrashedTag,
                        danger: true,
                      ),
                  ],
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                Text(
                  '${_wall(event.timezone, event.startsAt)} → '
                  '${_wall(event.timezone, event.endsAt)}',
                  key: const Key('event-admin-dates-value'),
                ),
                Text(
                  [?event.venue, ?event.city, ?event.venueAddress].join(' · '),
                  style: muted,
                ),
                if (event.capacity case final capacity?)
                  Text(l10n.adminEventsCapacityValue(capacity), style: muted),
                if (event.trashed && event.purgeDueAt != null)
                  Text(
                    l10n.adminOrgsPurgeOn(_day(event.purgeDueAt!)),
                    style: muted,
                  ),
                if (event.description case final description?) ...[
                  const SizedBox(height: TicketSurSpacing.xs),
                  Text(description),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: TicketSurSpacing.md),
            TikeoCard(
              key: const Key('event-admin-actions'),
              child: Wrap(
                spacing: TicketSurSpacing.xs,
                runSpacing: TicketSurSpacing.xs,
                children: actions,
              ),
            ),
          ],
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            key: const Key('event-admin-organization'),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.apartment_rounded),
              title: Text(event.organizationName),
              subtitle: event.organizationClosed
                  ? Text(l10n.adminOrgsClosedTag)
                  : null,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: event.organizationId.isEmpty
                  ? null
                  : () => unawaited(
                      context.push(
                        AppRoutes.consoleOrganization(event.organizationId),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            key: const Key('event-admin-tickets'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.adminEventsTickets, style: textTheme.titleMedium),
                const SizedBox(height: TicketSurSpacing.xs),
                Text(
                  l10n.adminEventsTicketsCount(
                    event.ticketsTotal,
                    event.ticketsValid,
                    event.ticketsAdmitted,
                    event.ticketsRevoked,
                  ),
                ),
                for (final category in event.categories)
                  ListTile(
                    key: Key('event-admin-category-${category.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      category.isInvitation
                          ? Icons.card_giftcard_rounded
                          : Icons.confirmation_number_rounded,
                    ),
                    title: Text(category.name),
                    subtitle: Text(
                      l10n.adminOrgsEventTickets(
                        category.issued,
                        category.admitted,
                      ),
                    ),
                  ),
                if (event.checkpoints.isNotEmpty)
                  Text(
                    l10n.adminEventsDoors(event.checkpoints.join(', ')),
                    style: muted,
                  ),
              ],
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            key: const Key('event-admin-history'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.adminAccountsHistory, style: textTheme.titleMedium),
                if (event.actions.isEmpty)
                  Text(l10n.adminEventsNoHistory, style: muted),
                for (final action in event.actions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_rounded),
                    title: Text(auditActionLabel(l10n, action.action)),
                    subtitle: Text(
                      '${_when(action.at)} · ${action.by}\n'
                      '${l10n.adminAccountsReasonValue(action.reason)}',
                    ),
                    isThreeLine: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: TicketSurSpacing.xl),
        ],
      ),
    );
  }
}

/// Début et fin, en heure locale de l'événement.
class _DatesSheet extends StatefulWidget {
  const new({required this.event});

  final AdminEventDetail event;

  @override
  State<_DatesSheet> createState() => _DatesSheetState();
}

class _DatesSheetState extends State<_DatesSheet> {
  late DateTime _start = wallTimeIn(
    widget.event.timezone,
    widget.event.startsAt,
  );
  late DateTime _end = wallTimeIn(widget.event.timezone, widget.event.endsAt);
  String? _error;

  Future<DateTime?> _pick(DateTime current) async {
    final day = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 1),
      lastDate: DateTime(current.year + 3),
    );
    if (day == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return null;
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final zone = widget.event.timezone;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        0,
        TicketSurSpacing.md,
        TicketSurSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.adminEventsDates,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(l10n.adminEventsDatesHint(timeZoneLabel(zone))),
          ListTile(
            key: const Key('event-dates-start'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.adminEventsStart),
            subtitle: Text(formatDateAtTime(_start)),
            trailing: const Icon(Icons.edit_calendar_rounded),
            onTap: () async {
              final picked = await _pick(_start);
              if (picked != null) setState(() => _start = picked);
            },
          ),
          ListTile(
            key: const Key('event-dates-end'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.adminEventsEnd),
            subtitle: Text(formatDateAtTime(_end)),
            trailing: const Icon(Icons.edit_calendar_rounded),
            onTap: () async {
              final picked = await _pick(_end);
              if (picked != null) setState(() => _end = picked);
            },
          ),
          if (_error case final error?)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: TicketSurSpacing.sm),
          FilledButton(
            key: const Key('event-dates-submit'),
            onPressed: () {
              if (!_end.isAfter(_start)) {
                setState(() => _error = l10n.adminEventsErrorEndBeforeStart);
                return;
              }
              Navigator.of(context).pop((
                instantFromWallTime(zone, _start),
                instantFromWallTime(zone, _end),
              ));
            },
            child: Text(l10n.adminEventsNext),
          ),
        ],
      ),
    );
  }
}

/// Structure de destination d'un déplacement.
class _OrganizationPicker extends ConsumerStatefulWidget {
  const new({required this.excludeId});

  final String excludeId;

  @override
  ConsumerState<_OrganizationPicker> createState() =>
      _OrganizationPickerState();
}

class _OrganizationPickerState extends ConsumerState<_OrganizationPicker> {
  final _search = TextEditingController();
  List<AdminOrganization>? _results;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final text = _search.text.trim();
    if (text.length < 2) return;
    try {
      final rows = await ref
          .read(adminRepositoryProvider)
          .organizations(search: text, limit: 10);
      if (mounted) {
        setState(
          () => _results = [
            for (final org in rows)
              if (org.active && org.id != widget.excludeId) org,
          ],
        );
      }
    } on Object {
      if (mounted) setState(() => _results = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        0,
        TicketSurSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + TicketSurSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.adminEventsMoveTo,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextField(
              key: const Key('move-search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => unawaited(_find()),
              decoration: InputDecoration(
                labelText: l10n.consoleSearchOrganizations,
                suffixIcon: IconButton(
                  key: const Key('move-find'),
                  tooltip: l10n.consoleSearchOrganizations,
                  onPressed: () => unawaited(_find()),
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            if (_results case final results?)
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: TicketSurSpacing.xs),
                  child: Text(l10n.consoleEmpty, key: const Key('move-none')),
                )
              else
                for (final org in results)
                  ListTile(
                    key: Key('move-org-${org.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.apartment_rounded),
                    title: Text(org.name),
                    subtitle: Text(org.ownerName),
                    onTap: () => Navigator.of(context).pop(org),
                  ),
          ],
        ),
      ),
    );
  }
}

/// Émettre des tickets anonymes d'une catégorie (réglage de la console).
class _IssueSheet extends StatefulWidget {
  const new({required this.event});

  final AdminEventDetail event;

  @override
  State<_IssueSheet> createState() => _IssueSheetState();
}

class _IssueSheetState extends State<_IssueSheet> {
  late String _category = widget.event.categories.first.id;
  final _count = TextEditingController(text: '1');
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _count.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        0,
        TicketSurSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + TicketSurSpacing.md,
      ),
      child: SingleChildScrollView(
        child: RadioGroup<String>(
          groupValue: _category,
          onChanged: (value) => setState(() => _category = value!),
          child: Column(
            key: const Key('issue-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.adminEventsIssue,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(l10n.adminEventsIssueHint),
              for (final category in widget.event.categories)
                RadioListTile<String>(
                  key: Key('issue-cat-${category.id}'),
                  value: category.id,
                  title: Text(category.name),
                ),
              TextField(
                key: const Key('issue-count'),
                controller: _count,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.adminEventsQuantity,
                ),
              ),
              TextField(
                key: const Key('issue-reason'),
                controller: _reason,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: l10n.adminAccountsReason,
                ),
              ),
              if (_error case final error?)
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              FilledButton(
                key: const Key('issue-submit'),
                onPressed: () {
                  final count = int.tryParse(_count.text.trim()) ?? 0;
                  if (count < 1 || count > 1000) {
                    setState(() => _error = l10n.adminTicketsErrorQuantity);
                    return;
                  }
                  if (_reason.text.trim().length < 3) {
                    setState(() => _error = l10n.adminAccountsErrorReason);
                    return;
                  }
                  Navigator.of(context)
                      .pop((_category, count, _reason.text.trim()));
                },
                child: Text(l10n.adminEventsIssue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
