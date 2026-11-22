import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/status_chip.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/announcements/application/announcement_providers.dart';
import 'package:ticketsur/features/announcements/domain/announcement.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart'
    show formatEventDay, formatEventTime;
import 'package:ticketsur/l10n/l10n.dart';

String _when(DateTime instant) => formatDateAtTime(instant.toLocal());

String audienceLabel(AppLocalizations l10n, AnnouncementAudience a) =>
    switch (a) {
      AnnouncementAudience.visitors => l10n.consoleAudienceVisitors,
      AnnouncementAudience.users => l10n.consoleAudienceUsers,
      AnnouncementAudience.promoters => l10n.consoleAudiencePromoters,
      AnnouncementAudience.controllers => l10n.consoleAudienceControllers,
    };

String _failure(AppLocalizations l10n, Object error) => switch (error) {
  AnnouncementFailure.invalid => l10n.consoleAnnouncementInvalid,
  AnnouncementFailure.started => l10n.consoleAnnouncementStarted,
  _ => l10n.consoleActionError,
};

/// Console : annonces publiées dans l'application.
class ConsoleAnnouncementsPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleAnnouncementsPage> createState() =>
      _ConsoleAnnouncementsPageState();
}

class _ConsoleAnnouncementsPageState
    extends ConsumerState<ConsoleAnnouncementsPage> {
  int _generation = 0;

  Future<void> _create() async {
    final published = await context.push<bool>(
      AppRoutes.consoleAnnouncementNew,
    );
    if (published ?? false) {
      ref.invalidate(myAnnouncementsProvider);
      if (mounted) setState(() => _generation++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ref.watch(announcementRepositoryProvider);
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.consoleNavAnnouncements)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('console-announcement-new'),
        heroTag: 'console-announcement-new',
        onPressed: () => unawaited(_create()),
        icon: const Icon(Icons.campaign_rounded),
        label: Text(l10n.consoleAnnouncementNew),
      ),
      body: ConsolePagedList<Announcement>(
        key: ValueKey(('announcements', _generation)),
        pageSize: 50,
        load: (offset, _) => repository.all(offset: offset),
        itemBuilder: (context, announcement, reload) => _AnnouncementTile(
          announcement: announcement,
          onChanged: () {
            ref.invalidate(myAnnouncementsProvider);
            reload();
          },
        ),
      ),
    );
  }
}

class _AnnouncementTile extends ConsumerWidget {
  const new({required this.announcement, required this.onChanged});

  final Announcement announcement;
  final VoidCallback onChanged;

  Future<void> _edit(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            ConsoleAnnouncementFormPage(announcement: announcement),
      ),
    );
    if (saved ?? false) onChanged();
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final confirmed = await showConsoleConfirm(
      context,
      title: l10n.consoleAnnouncementArchive,
      body: announcement.title,
      confirmLabel: l10n.consoleAnnouncementArchive,
      needsReason: false,
      confirmKey: const Key('console-announcement-archive-confirm'),
    );
    if (confirmed == null) return;
    try {
      await ref.read(announcementRepositoryProvider).archive(announcement.id);
      toast.success(l10n.consoleAnnouncementArchived);
      onChanged();
    } on Object catch (error) {
      toast.error(_failure(l10n, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final a = announcement;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );
    return Card(
      key: Key('console-announcement-${a.id}'),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  if (a.important)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: TicketSurSpacing.xs,
                      ),
                      child: Icon(
                        Icons.campaign_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  Expanded(child: Text(a.title, style: textTheme.titleMedium)),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth / 2,
                    ),
                    child: StatusChip(
                      label: a.scheduled
                          ? l10n.consoleAnnouncementScheduled
                          : a.active
                          ? l10n.consoleAnnouncementActive
                          : l10n.consoleAnnouncementInactive,
                      tone: a.scheduled
                          ? StatusTone.info
                          : a.active
                          ? StatusTone.positive
                          : StatusTone.neutral,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TicketSurSpacing.xxs),
            Text(a.body),
            const SizedBox(height: TicketSurSpacing.xs),
            Text(
              switch ((a.targetKind, a.targetName)) {
                ('organization', final name?) =>
                  l10n.consoleAnnouncementForOrganization(name),
                ('event', final name?) => l10n.consoleAnnouncementForEvent(
                  name,
                ),
                _ => [
                  for (final audience in AnnouncementAudience.values)
                    if (a.audiences.contains(audience))
                      audienceLabel(l10n, audience),
                ].join(' · '),
              },
              key: Key('console-announcement-audience-${a.id}'),
              style: textTheme.labelMedium,
            ),
            Text(
              [
                if (a.scheduled)
                  l10n.consoleAnnouncementStartsAt(_when(a.startsAt))
                else
                  _when(a.startsAt),
                if (a.endsAt case final end?)
                  l10n.consoleAnnouncementUntil(_when(end)),
                ?a.authorName,
              ].join(' · '),
              style: muted,
            ),
            if (a.active || a.scheduled)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    if (a.scheduled && !a.targeted)
                      TextButton.icon(
                        key: Key('console-announcement-edit-${a.id}'),
                        onPressed: () => unawaited(_edit(context)),
                        icon: const Icon(Icons.edit_rounded),
                        label: Text(l10n.consoleAnnouncementEdit),
                      ),
                    TextButton.icon(
                      key: Key('console-announcement-archive-${a.id}'),
                      onPressed: () => unawaited(_archive(context, ref)),
                      icon: const Icon(Icons.visibility_off_rounded),
                      label: Text(l10n.consoleAnnouncementArchive),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Durées d'affichage proposées.
enum _Duration { day, week, month, none }

/// Console : formulaire d'une annonce (nouvelle, ou programmée à modifier).
class ConsoleAnnouncementFormPage extends ConsumerStatefulWidget {
  const new({this.announcement, super.key});

  /// Annonce programmée à modifier.
  final Announcement? announcement;

  @override
  ConsumerState<ConsoleAnnouncementFormPage> createState() =>
      _ConsoleAnnouncementFormPageState();
}

class _ConsoleAnnouncementFormPageState
    extends ConsumerState<ConsoleAnnouncementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final Set<AnnouncementAudience> _audiences = {};
  bool _important = false;
  _Duration _duration = _Duration.week;
  bool _sending = false;
  bool _audienceMissing = false;

  /// Début programmé (heure locale) ; `null` = tout de suite.
  DateTime? _startsAt;

  bool get _editing => widget.announcement != null;

  @override
  void initState() {
    super.initState();
    if (widget.announcement case final a?) {
      _title.text = a.title;
      _body.text = a.body;
      _audiences.addAll(a.audiences);
      _important = a.important;
      _startsAt = a.startsAt.toLocal();
      _duration = switch (a.endsAt?.difference(a.startsAt).inHours) {
        null => _Duration.none,
        <= 24 => _Duration.day,
        <= 24 * 7 => _Duration.week,
        _ => _Duration.month,
      };
    }
  }

  /// Demain à 9 h, heure du téléphone.
  static DateTime _defaultStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 9);
  }

  Future<void> _pickDate() async {
    final current = _startsAt ?? _defaultStart();
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 89)),
    );
    if (day == null || !mounted) return;
    setState(
      () => _startsAt = DateTime(
        day.year,
        day.month,
        day.day,
        current.hour,
        current.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final current = _startsAt ?? _defaultStart();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    setState(
      () => _startsAt = DateTime(
        current.year,
        current.month,
        current.day,
        time.hour,
        time.minute,
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_sending) return;
    final l10n = context.l10n;
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _audienceMissing = _audiences.isEmpty);
    if (!valid || _audiences.isEmpty) return;
    final toast = Toaster.of(context);
    final now = DateTime.now();
    final startsAt = _startsAt;
    if (startsAt != null && !startsAt.isAfter(now)) {
      toast.error(l10n.consoleAnnouncementStartPast);
      return;
    }
    final from = startsAt ?? now;
    final endsAt = switch (_duration) {
      _Duration.day => from.add(const Duration(days: 1)),
      _Duration.week => from.add(const Duration(days: 7)),
      _Duration.month => from.add(const Duration(days: 30)),
      _Duration.none => null,
    };
    setState(() => _sending = true);
    final repository = ref.read(announcementRepositoryProvider);
    try {
      if (widget.announcement case final a?) {
        await repository.update(
          a.id,
          title: _title.text,
          body: _body.text,
          audiences: _audiences,
          important: _important,
          startsAt: startsAt,
          endsAt: endsAt,
        );
        toast.success(l10n.consoleAnnouncementSaved);
      } else {
        await repository.publish(
          title: _title.text,
          body: _body.text,
          audiences: _audiences,
          important: _important,
          endsAt: endsAt,
          startsAt: startsAt,
        );
        toast.success(
          startsAt == null
              ? l10n.consoleAnnouncementPublished
              : l10n.consoleAnnouncementScheduledToast(_when(startsAt)),
        );
      }
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go(AppRoutes.consoleAnnouncements);
      }
    } on Object catch (error) {
      toast.error(_failure(l10n, error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final durations = {
      _Duration.day: l10n.consoleDuration1d,
      _Duration.week: l10n.consoleDuration7d,
      _Duration.month: l10n.consoleDuration30d,
      _Duration.none: l10n.consoleDurationNone,
    };
    return Scaffold(
      appBar: TikeoAppBar(
        title: Text(
          _editing ? l10n.consoleAnnouncementEdit : l10n.consoleAnnouncementNew,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(TicketSurSpacing.lg),
            children: [
              TextFormField(
                key: const Key('announcement-title'),
                controller: _title,
                enabled: !_sending,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.consoleAnnouncementTitleLabel,
                ),
                validator: (value) => (value ?? '').trim().length < 3
                    ? l10n.consoleAnnouncementInvalid
                    : null,
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              TextFormField(
                key: const Key('announcement-body'),
                controller: _body,
                enabled: !_sending,
                minLines: 3,
                maxLines: 8,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.consoleAnnouncementBodyLabel,
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.consoleAnnouncementInvalid
                    : null,
              ),
              const SizedBox(height: TicketSurSpacing.md),
              Text(
                l10n.consoleAnnouncementAudience,
                style: theme.textTheme.titleSmall,
              ),
              for (final audience in AnnouncementAudience.values)
                CheckboxListTile(
                  key: Key('announcement-audience-${audience.wireName}'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(audienceLabel(l10n, audience)),
                  value: _audiences.contains(audience),
                  onChanged: _sending
                      ? null
                      : (checked) => setState(() {
                          if (checked ?? false) {
                            _audiences.add(audience);
                            _audienceMissing = false;
                          } else {
                            _audiences.remove(audience);
                          }
                        }),
                ),
              if (_audienceMissing)
                Text(
                  l10n.consoleAnnouncementAudienceRequired,
                  key: const Key('announcement-audience-missing'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              const SizedBox(height: TicketSurSpacing.sm),
              SwitchListTile(
                key: const Key('announcement-important'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.consoleAnnouncementImportant),
                value: _important,
                onChanged: _sending
                    ? null
                    : (value) => setState(() => _important = value),
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              Text(
                l10n.consoleAnnouncementStart,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              Wrap(
                spacing: TicketSurSpacing.xs,
                runSpacing: TicketSurSpacing.xs,
                children: [
                  ChoiceChip(
                    key: const Key('announcement-start-now'),
                    label: Text(l10n.consoleAnnouncementStartNow),
                    selected: _startsAt == null,
                    onSelected: _sending
                        ? null
                        : (_) => setState(() => _startsAt = null),
                  ),
                  ChoiceChip(
                    key: const Key('announcement-start-later'),
                    label: Text(l10n.consoleAnnouncementStartLater),
                    selected: _startsAt != null,
                    onSelected: _sending
                        ? null
                        : (_) => setState(() => _startsAt ??= _defaultStart()),
                  ),
                ],
              ),
              if (_startsAt case final start?) ...[
                const SizedBox(height: TicketSurSpacing.xs),
                Wrap(
                  spacing: TicketSurSpacing.xs,
                  runSpacing: TicketSurSpacing.xs,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('announcement-start-date'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: _sending ? null : _pickDate,
                      icon: const Icon(Icons.event_rounded),
                      label: Text(formatEventDay(start)),
                    ),
                    OutlinedButton.icon(
                      key: const Key('announcement-start-time'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: _sending ? null : _pickTime,
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(formatEventTime(start)),
                    ),
                  ],
                ),
                const SizedBox(height: TicketSurSpacing.xxs),
                Text(
                  _important
                      ? l10n.consoleAnnouncementScheduledPushHint
                      : l10n.consoleAnnouncementScheduledHint,
                  key: const Key('announcement-start-hint'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: TicketSurSpacing.sm),
              Text(
                l10n.consoleAnnouncementDuration,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              Wrap(
                spacing: TicketSurSpacing.xs,
                runSpacing: TicketSurSpacing.xs,
                children: [
                  for (final MapEntry(key: duration, value: label)
                      in durations.entries)
                    ChoiceChip(
                      key: Key('announcement-duration-${duration.name}'),
                      label: Text(label),
                      selected: duration == _duration,
                      onSelected: (_) => setState(() => _duration = duration),
                    ),
                ],
              ),
              const SizedBox(height: TicketSurSpacing.lg),
              FilledButton.icon(
                key: const Key('announcement-publish'),
                onPressed: _sending ? null : () => unawaited(_publish()),
                icon: Icon(
                  _startsAt == null
                      ? Icons.send_rounded
                      : Icons.schedule_send_rounded,
                ),
                label: Text(
                  _editing
                      ? l10n.profileSave
                      : _startsAt == null
                      ? l10n.consoleAnnouncementPublish
                      : l10n.consoleAnnouncementSchedule,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
