import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/announcements/application/announcement_providers.dart';
import 'package:ticketsur/features/announcements/domain/announcement.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _when(DateTime instant) =>
    DateFormat("d MMM y 'à' HH:mm", 'fr').format(instant.toLocal());

String audienceLabel(AppLocalizations l10n, AnnouncementAudience a) =>
    switch (a) {
      AnnouncementAudience.visitors => l10n.consoleAudienceVisitors,
      AnnouncementAudience.users => l10n.consoleAudienceUsers,
      AnnouncementAudience.promoters => l10n.consoleAudiencePromoters,
      AnnouncementAudience.controllers => l10n.consoleAudienceControllers,
    };

String _failure(AppLocalizations l10n, Object error) => switch (error) {
  AnnouncementFailure.invalid => l10n.consoleAnnouncementInvalid,
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
      appBar: AppBar(title: Text(l10n.consoleNavAnnouncements)),
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
            Row(
              children: [
                if (a.important)
                  Padding(
                    padding: const EdgeInsets.only(right: TicketSurSpacing.xs),
                    child: Icon(
                      Icons.campaign_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                Expanded(child: Text(a.title, style: textTheme.titleMedium)),
                ConsoleTag(
                  label: a.active
                      ? l10n.consoleAnnouncementActive
                      : l10n.consoleAnnouncementInactive,
                  danger: !a.active,
                ),
              ],
            ),
            const SizedBox(height: TicketSurSpacing.xxs),
            Text(a.body),
            const SizedBox(height: TicketSurSpacing.xs),
            Text(
              [
                for (final audience in AnnouncementAudience.values)
                  if (a.audiences.contains(audience))
                    audienceLabel(l10n, audience),
              ].join(' · '),
              style: textTheme.labelMedium,
            ),
            Text(
              [
                _when(a.startsAt),
                if (a.endsAt case final end?)
                  l10n.consoleAnnouncementUntil(_when(end)),
                ?a.authorName,
              ].join(' · '),
              style: muted,
            ),
            if (a.active)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: Key('console-announcement-archive-${a.id}'),
                  onPressed: () => unawaited(_archive(context, ref)),
                  icon: const Icon(Icons.visibility_off_rounded),
                  label: Text(l10n.consoleAnnouncementArchive),
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

/// Console : formulaire d'une annonce.
class ConsoleAnnouncementFormPage extends ConsumerStatefulWidget {
  const new({super.key});

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
    final endsAt = switch (_duration) {
      _Duration.day => now.add(const Duration(days: 1)),
      _Duration.week => now.add(const Duration(days: 7)),
      _Duration.month => now.add(const Duration(days: 30)),
      _Duration.none => null,
    };
    setState(() => _sending = true);
    try {
      await ref
          .read(announcementRepositoryProvider)
          .publish(
            title: _title.text,
            body: _body.text,
            audiences: _audiences,
            important: _important,
            endsAt: endsAt,
          );
      toast.success(l10n.consoleAnnouncementPublished);
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
      appBar: AppBar(title: Text(l10n.consoleAnnouncementNew)),
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
                icon: const Icon(Icons.send_rounded),
                label: Text(l10n.consoleAnnouncementPublish),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
