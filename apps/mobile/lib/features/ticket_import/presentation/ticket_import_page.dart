import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/success_burst.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/ticket_import/application/import_providers.dart';
import 'package:ticketsur/features/ticket_import/domain/import_plan.dart';
import 'package:ticketsur/features/ticket_import/domain/table_reader.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_share.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Émission en lot depuis une liste Excel ou CSV (lot 2).
///
/// Le fichier est lu sur l'appareil : chaque ligne est contrôlée avec les
/// règles du serveur et les erreurs sont citées par numéro de ligne avant
/// tout envoi. L'émission est ensuite faite en un seul appel, tout ou rien.
class TicketImportPage extends ConsumerStatefulWidget {
  const new({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<TicketImportPage> createState() => _TicketImportPageState();
}

/// Problème de lecture du fichier (format, taille, contenu).
enum _FileProblem { unsupported, legacy, unreadable, tooLarge, empty }

class _TicketImportPageState extends ConsumerState<TicketImportPage> {
  String? _fileName;
  CellTable? _table;
  _FileProblem? _fileProblem;
  String? _defaultCategoryId;
  bool _skipErrors = false;
  bool _busy = false;
  TicketFailure? _failure;
  List<TicketSecret>? _issued;

  Future<void> _pick() async {
    final PickedFile? file;
    try {
      file = await ref.read(importFilePickerProvider)();
    } on ImportFileTooLarge {
      setState(() => _fileProblem = _FileProblem.tooLarge);
      return;
    }
    if (file == null || !mounted) return;
    final picked = file;
    setState(() {
      _fileName = picked.name;
      _failure = null;
      _skipErrors = false;
      try {
        final table = readTable(picked.name, picked.bytes);
        _table = table;
        _fileProblem = table.isEmpty ? _FileProblem.empty : null;
      } on TableReadFailure catch (failure) {
        _table = null;
        _fileProblem = switch (failure) {
          TableReadFailure.unsupported => _FileProblem.unsupported,
          TableReadFailure.legacyExcel => _FileProblem.legacy,
          TableReadFailure.unreadable => _FileProblem.unreadable,
        };
      }
    });
  }

  Future<void> _shareTemplate(List<TicketCategory> categories) async {
    await ref.read(shareFilesProvider)([
      (
        bytes: Uint8List.fromList(utf8.encode(importTemplateCsv(categories))),
        name: 'modele-liste-tickets.csv',
        mimeType: 'text/csv',
      ),
    ]);
  }

  Future<void> _issue(ImportPlan plan) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final issued = await ref
          .read(ticketActionsProvider)
          .issueNamed(widget.eventId, plan.ticketRows);
      if (mounted) setState(() => _issued = issued);
    } on TicketFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final event = ref.watch(eventByIdProvider(widget.eventId));
    final categories =
        ref.watch(categoriesProvider(widget.eventId)).value ??
        const <TicketCategory>[];
    final defaultCategoryId =
        categories.where((c) => c.id == _defaultCategoryId).firstOrNull?.id ??
        categories.firstOrNull?.id;
    final table = _table;
    final plan = table == null || _fileProblem != null
        ? null
        : buildImportPlan(
            table,
            categories: categories,
            defaultCategoryId: defaultCategoryId,
          );
    final issued = _issued;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.importTitle),
            if (event != null)
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      body: event == null
          ? Center(child: Text(l10n.eventNotFoundTitle))
          : issued != null
          ? _Done(event: event, issued: issued)
          : ListView(
              padding: const EdgeInsets.all(TicketSurSpacing.md),
              children: [
                _FileCard(
                  fileName: _fileName,
                  rowsRead: plan?.rows.length,
                  problem: _fileProblem,
                  onPick: _busy ? null : () => unawaited(_pick()),
                  onTemplate: () => unawaited(_shareTemplate(categories)),
                ),
                const SizedBox(height: TicketSurSpacing.md),
                if (categories.isEmpty)
                  _Notice(
                    key: const Key('import-no-category'),
                    text: l10n.importNoCategory,
                    color: TicketSurColors.warning,
                  )
                else
                  DropdownButtonFormField<String>(
                    key: const Key('import-default-category'),
                    initialValue: defaultCategoryId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.importDefaultCategory,
                    ),
                    items: [
                      for (final c in categories)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (id) => setState(() => _defaultCategoryId = id),
                  ),
                if (plan != null) ...[
                  const SizedBox(height: TicketSurSpacing.md),
                  FadeSlideIn(
                    child: _PlanView(
                      plan: plan,
                      categories: categories,
                      eventCapacity: event.capacity,
                      skipErrors: _skipErrors,
                      onSkipErrors: (value) =>
                          setState(() => _skipErrors = value),
                    ),
                  ),
                ],
                if (_failure case final failure?) ...[
                  const SizedBox(height: TicketSurSpacing.md),
                  _Notice(
                    key: const Key('import-error'),
                    text: ticketFailureMessage(l10n, failure),
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
                const SizedBox(height: TicketSurSpacing.lg),
                if (plan != null)
                  _SubmitButton(
                    plan: plan,
                    busy: _busy,
                    ready: _ready(plan, categories, event),
                    onPressed: () => unawaited(_issue(plan)),
                  ),
                const SizedBox(height: TicketSurSpacing.xl),
              ],
            ),
    );
  }

  /// L'envoi n'est proposé que s'il a toutes les chances d'aboutir.
  bool _ready(
    ImportPlan plan,
    List<TicketCategory> categories,
    TicketEvent event,
  ) {
    final valid = plan.valid.length;
    final hasName =
        plan.columns.containsKey(ImportColumn.name) ||
        plan.columns.containsKey(ImportColumn.firstName);
    return hasName &&
        valid > 0 &&
        valid <= maxNamedBatchSize &&
        (plan.errors.isEmpty || _skipErrors) &&
        plan.quotaIssues(categories, eventCapacity: event.capacity).isEmpty;
  }
}

// -----------------------------------------------------------------------------
// Fichier
// -----------------------------------------------------------------------------

class _FileCard extends StatelessWidget {
  const new({
    required this.onPick,
    required this.onTemplate,
    this.fileName,
    this.rowsRead,
    this.problem,
  });

  final String? fileName;
  final int? rowsRead;
  final _FileProblem? problem;
  final VoidCallback? onPick;
  final VoidCallback onTemplate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final name = fileName;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.importIntro, style: theme.textTheme.bodyMedium),
            if (name != null) ...[
              const SizedBox(height: TicketSurSpacing.sm),
              ListTile(
                key: const Key('import-file'),
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  name.toLowerCase().endsWith('.csv')
                      ? Icons.description_outlined
                      : Icons.table_chart_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(name, overflow: TextOverflow.ellipsis),
                subtitle: rowsRead == null
                    ? null
                    : Text(l10n.importRowsRead(rowsRead!)),
              ),
            ],
            if (problem case final problem?) ...[
              const SizedBox(height: TicketSurSpacing.xs),
              Text(
                switch (problem) {
                  _FileProblem.unsupported => l10n.importErrorUnsupported,
                  _FileProblem.legacy => l10n.importErrorLegacy,
                  _FileProblem.unreadable => l10n.importErrorUnreadable,
                  _FileProblem.tooLarge => l10n.importErrorTooLarge,
                  _FileProblem.empty => l10n.importErrorEmpty,
                },
                key: const Key('import-file-error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: TicketSurSpacing.md),
            FilledButton.icon(
              key: const Key('import-pick'),
              onPressed: onPick,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(name == null ? l10n.importPick : l10n.importChange),
            ),
            TextButton.icon(
              key: const Key('import-template'),
              onPressed: onTemplate,
              icon: const Icon(Icons.download_rounded),
              label: Text(l10n.importTemplate),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Aperçu et contrôles
// -----------------------------------------------------------------------------

String _columnLabel(AppLocalizations l10n, ImportColumn column) =>
    switch (column) {
      ImportColumn.name => l10n.importColumnName,
      ImportColumn.firstName => l10n.importColumnFirstName,
      ImportColumn.phone => l10n.importColumnPhone,
      ImportColumn.email => l10n.importColumnEmail,
      ImportColumn.category => l10n.importColumnCategory,
    };

/// Lettre de colonne de tableur (0 → A, 26 → AA).
String columnLetter(int index) {
  var n = index + 1;
  final buffer = StringBuffer();
  while (n > 0) {
    final rem = (n - 1) % 26;
    buffer.write(String.fromCharCode(0x41 + rem));
    n = (n - 1) ~/ 26;
  }
  return buffer.toString().split('').reversed.join();
}

String _problemLabel(AppLocalizations l10n, ImportRow row) =>
    switch (row.problem!) {
      RowProblem.nameMissing => l10n.importProblemNameMissing,
      RowProblem.nameTooLong => l10n.importProblemNameTooLong,
      RowProblem.phoneInvalid => l10n.importProblemPhone,
      RowProblem.emailInvalid => l10n.importProblemEmail,
      RowProblem.categoryUnknown => switch (row.categoryLabel) {
        final label? => l10n.importProblemCategory(label),
        null => l10n.importProblemNoCategory,
      },
    };

String _warningLabel(AppLocalizations l10n, ImportRow row) => [
  for (final warning in row.warnings)
    switch (warning) {
      RowWarning.duplicatePhone => l10n.importWarningPhone,
      RowWarning.duplicateEmail => l10n.importWarningEmail,
    },
].join(', ');

class _PlanView extends StatelessWidget {
  const new({
    required this.plan,
    required this.categories,
    required this.skipErrors,
    required this.onSkipErrors,
    this.eventCapacity,
  });

  final ImportPlan plan;
  final List<TicketCategory> categories;
  final int? eventCapacity;
  final bool skipErrors;
  final ValueChanged<bool> onSkipErrors;

  static const int _shown = 20;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final valid = plan.valid;
    final errors = plan.errors;
    final warned = plan.warned;
    final hasName =
        plan.columns.containsKey(ImportColumn.name) ||
        plan.columns.containsKey(ImportColumn.firstName);
    final quota = plan.quotaIssues(categories, eventCapacity: eventCapacity);
    final categoryName = {for (final c in categories) c.id: c.name};
    final columns = plan.columns.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: TicketSurSpacing.xs,
          runSpacing: TicketSurSpacing.xs,
          children: [
            _CountChip(
              key: const Key('import-ready'),
              icon: Icons.check_circle_rounded,
              color: TicketSurColors.successStrong,
              label: l10n.importReady(valid.length),
            ),
            if (errors.isNotEmpty)
              _CountChip(
                key: const Key('import-error-count'),
                icon: Icons.error_rounded,
                color: scheme.error,
                label: l10n.importErrorCount(errors.length),
              ),
            if (warned.isNotEmpty)
              _CountChip(
                key: const Key('import-warning-count'),
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFF8A5A00),
                label: l10n.importWarningCount(warned.length),
              ),
          ],
        ),
        const SizedBox(height: TicketSurSpacing.md),
        if (!hasName)
          _Notice(
            key: const Key('import-no-name'),
            text: l10n.importErrorNoName,
            color: scheme.error,
          ),
        if (valid.length > maxNamedBatchSize)
          _Notice(
            key: const Key('import-too-many'),
            text: l10n.importTooMany,
            color: scheme.error,
          ),
        for (final issue in quota)
          _Notice(
            key: Key('import-quota-${issue.categoryName ?? 'event'}'),
            text: switch (issue.categoryName) {
              final name? => l10n.importQuotaCategory(
                name,
                issue.wanted,
                issue.remaining,
              ),
              null => l10n.importQuotaEvent(issue.wanted, issue.remaining),
            },
            color: scheme.error,
          ),
        _Section(
          title: l10n.importColumnsTitle,
          subtitle: plan.headerLine == null ? l10n.importColumnsGuessed : null,
          child: Wrap(
            spacing: TicketSurSpacing.xs,
            runSpacing: TicketSurSpacing.xs,
            children: [
              for (final MapEntry(key: column, value: index) in columns)
                Chip(
                  key: Key('import-column-${column.name}'),
                  label: Text(
                    index < plan.headers.length &&
                            plan.headers[index].trim().isNotEmpty
                        ? l10n.importColumnFrom(
                            _columnLabel(l10n, column),
                            plan.headers[index].trim(),
                          )
                        : l10n.importColumnAt(
                            _columnLabel(l10n, column),
                            columnLetter(index),
                          ),
                  ),
                ),
            ],
          ),
        ),
        if (plan.perCategory.isNotEmpty)
          _Section(
            title: l10n.importPerCategoryTitle,
            child: Wrap(
              spacing: TicketSurSpacing.xs,
              runSpacing: TicketSurSpacing.xs,
              children: [
                for (final MapEntry(key: id, value: count)
                    in plan.perCategory.entries)
                  Chip(
                    key: Key('import-category-$id'),
                    avatar: const Icon(Icons.confirmation_number_outlined),
                    label: Text('${categoryName[id] ?? id} · $count'),
                  ),
              ],
            ),
          ),
        if (errors.isNotEmpty)
          _Section(
            key: const Key('import-errors'),
            title: l10n.importErrorsTitle,
            child: _LineList(
              lines: [
                for (final row in errors)
                  l10n.importLine(row.line, _problemLabel(l10n, row)),
              ],
              color: scheme.error,
              shown: _shown,
            ),
          ),
        if (errors.isNotEmpty)
          CheckboxListTile(
            key: const Key('import-skip-errors'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: skipErrors,
            onChanged: (value) => onSkipErrors(value ?? false),
            title: Text(l10n.importSkipErrors),
          ),
        if (warned.isNotEmpty)
          _Section(
            key: const Key('import-warnings'),
            title: l10n.importWarningsTitle,
            child: _LineList(
              lines: [
                for (final row in warned)
                  l10n.importLine(row.line, _warningLabel(l10n, row)),
              ],
              shown: _shown,
            ),
          ),
        if (valid.isNotEmpty && hasName)
          _Section(
            key: const Key('import-preview'),
            title: l10n.importPreviewTitle,
            child: Column(
              children: [
                for (final row in valid.take(10))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text(
                        '${row.line}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    title: Text(row.holder!.name ?? ''),
                    subtitle: Text(
                      [
                        ?row.holder!.phone,
                        ?row.holder!.email,
                        categoryName[row.categoryId] ?? '',
                      ].join(' · '),
                    ),
                  ),
                if (valid.length > 10)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.importMore(valid.length - 10),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LineList extends StatelessWidget {
  const new({required this.lines, required this.shown, this.color});

  final List<String> lines;
  final int shown;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines.take(shown))
          Padding(
            padding: const EdgeInsets.only(bottom: TicketSurSpacing.xxs),
            child: Text(line, style: style),
          ),
        if (lines.length > shown)
          Text(
            l10n.importMore(lines.length - shown),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const new({
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: TicketSurSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: textTheme.titleSmall),
          if (subtitle case final text?) Text(text, style: textTheme.bodySmall),
          const SizedBox(height: TicketSurSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const new({
    required this.icon,
    required this.color,
    required this.label,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, color: color, size: 18),
    label: Text(label),
  );
}

class _Notice extends StatelessWidget {
  const new({required this.text, required this.color, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
    padding: const EdgeInsets.all(TicketSurSpacing.sm),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(TicketSurRadii.sm),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: color, size: 20),
        const SizedBox(width: TicketSurSpacing.xs),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _SubmitButton extends StatelessWidget {
  const new({
    required this.plan,
    required this.busy,
    required this.ready,
    required this.onPressed,
  });

  final ImportPlan plan;
  final bool busy;
  final bool ready;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    key: const Key('import-submit'),
    onPressed: ready && !busy ? onPressed : null,
    icon: busy
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.add_card_rounded),
    label: Text(context.l10n.importSubmit(plan.valid.length)),
  );
}

// -----------------------------------------------------------------------------
// Fin
// -----------------------------------------------------------------------------

class _Done extends ConsumerStatefulWidget {
  const new({required this.event, required this.issued});

  final TicketEvent event;
  final List<TicketSecret> issued;

  @override
  ConsumerState<_Done> createState() => _DoneState();
}

class _DoneState extends ConsumerState<_Done> {
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await shareTicketsPdf(
        context,
        ref,
        event: widget.event,
        tickets: widget.issued,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      key: const Key('import-done'),
      padding: const EdgeInsets.all(TicketSurSpacing.lg),
      children: [
        const SizedBox(height: TicketSurSpacing.lg),
        const Center(child: SuccessBurst(size: 80)),
        const SizedBox(height: TicketSurSpacing.md),
        Text(
          l10n.issueDoneTitle(widget.issued.length),
          key: const Key('import-done-title'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: TicketSurSpacing.xs),
        Text(l10n.issueDoneBody, textAlign: TextAlign.center),
        const SizedBox(height: TicketSurSpacing.lg),
        FilledButton.icon(
          key: const Key('import-share-pdf'),
          onPressed: _sharing ? null : () => unawaited(_share()),
          icon: _sharing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_rounded),
          label: Text(l10n.issueSharePdf),
        ),
        const SizedBox(height: TicketSurSpacing.xs),
        OutlinedButton(
          key: const Key('import-see'),
          onPressed: () => context.go(AppRoutes.tickets),
          child: Text(l10n.issueSeeTickets),
        ),
      ],
    );
  }
}
