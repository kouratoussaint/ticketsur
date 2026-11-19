import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/legal/application/legal_providers.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/features/legal/presentation/legal_pages.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Passages entre crochets restant à compléter.
int legalPlaceholderCount(String text) =>
    RegExp(r'\[[^\]]+\]').allMatches(text).length;

/// Console : les deux documents légaux.
class ConsoleLegalPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.consoleNavLegal)),
      body: ListView(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: [
          for (final slug in LegalSlug.values)
            Card(
              child: switch (ref.watch(legalDocumentProvider(slug))) {
                AsyncData(:final value) => ListTile(
                  key: Key('console-legal-${slug.wireName}'),
                  leading: Icon(
                    slug == LegalSlug.terms
                        ? Icons.gavel_rounded
                        : Icons.privacy_tip_rounded,
                    color: context.palette.accentText,
                  ),
                  title: Text(value.title),
                  subtitle: Text(
                    [
                      l10n.consoleLegalVersion(
                        value.version,
                        legalDate(value.updatedAt),
                      ),
                      if (legalPlaceholderCount(value.body) case final n
                          when n > 0)
                        l10n.consoleLegalPlaceholders(n),
                    ].join('\n'),
                  ),
                  isThreeLine: legalPlaceholderCount(value.body) > 0,
                  trailing: const Icon(Icons.edit_rounded),
                  onTap: () async {
                    await context.push(AppRoutes.consoleLegalEdit(slug));
                    ref.invalidate(legalDocumentProvider(slug));
                  },
                ),
                AsyncError() => ListTile(
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: Text(legalTitle(l10n, slug)),
                  subtitle: Text(l10n.legalLoadError),
                  trailing: TextButton(
                    onPressed: () =>
                        ref.invalidate(legalDocumentProvider(slug)),
                    child: Text(l10n.legalRetry),
                  ),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(TicketSurSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
            ),
        ],
      ),
    );
  }
}

/// Console : modifier un document, avec aperçu, puis publier une version.
class ConsoleLegalEditPage extends ConsumerStatefulWidget {
  const new({required this.slug, super.key});

  final LegalSlug slug;

  @override
  ConsumerState<ConsoleLegalEditPage> createState() =>
      _ConsoleLegalEditPageState();
}

class _ConsoleLegalEditPageState extends ConsumerState<ConsoleLegalEditPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  LegalDocument? _loaded;
  bool _preview = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _fill(LegalDocument document) {
    if (_loaded != null) return;
    _loaded = document;
    _title.text = document.title;
    _body.text = document.body;
  }

  Future<void> _save() async {
    final loaded = _loaded;
    if (loaded == null || _saving) return;
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.length < 3 || title.length > 80 || body.length < 20) {
      toast.error(l10n.consoleLegalInvalid);
      return;
    }
    final confirmed = await showConsoleConfirm(
      context,
      title: l10n.consoleLegalConfirm(loaded.version + 1),
      body: l10n.consoleLegalConfirmBody,
      confirmLabel: l10n.consoleLegalSave,
      needsReason: false,
      destructive: false,
      confirmKey: const Key('console-legal-confirm'),
    );
    if (confirmed == null) return;
    setState(() => _saving = true);
    try {
      final version = await ref
          .read(legalRepositoryProvider)
          .save(widget.slug, title: title, body: body);
      ref.invalidate(legalDocumentProvider(widget.slug));
      toast.success(l10n.consoleLegalSaved(version));
      if (mounted) context.popOr(AppRoutes.consoleLegal);
    } on Object catch (error) {
      toast.error(
        error == LegalFailure.invalid
            ? l10n.consoleLegalInvalid
            : l10n.consoleActionError,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final document = ref.watch(legalDocumentProvider(widget.slug));
    if (document.value case final value?) _fill(value);
    return Scaffold(
      appBar: AppBar(
        title: Text(legalTitle(l10n, widget.slug)),
        actions: [
          if (_loaded != null)
            TextButton(
              key: const Key('console-legal-save'),
              onPressed: _saving ? null : () => unawaited(_save()),
              child: Text(l10n.consoleLegalSave),
            ),
        ],
      ),
      body: switch (document) {
        AsyncError() when _loaded == null => Center(
          child: Text(l10n.legalLoadError, textAlign: TextAlign.center),
        ),
        _ when _loaded == null => const Center(
          child: CircularProgressIndicator(),
        ),
        _ => ListView(
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(l10n.consoleLegalEdit),
                  icon: const Icon(Icons.edit_rounded),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(l10n.consoleLegalPreview),
                  icon: const Icon(Icons.visibility_rounded),
                ),
              ],
              selected: {_preview},
              onSelectionChanged: (value) =>
                  setState(() => _preview = value.first),
            ),
            const SizedBox(height: TicketSurSpacing.md),
            if (_preview) ...[
              Text(
                _title.text,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: TicketSurSpacing.md),
              LegalBodyView(
                key: const Key('console-legal-preview'),
                body: _body.text,
              ),
            ] else ...[
              TextField(
                key: const Key('console-legal-title'),
                controller: _title,
                enabled: !_saving,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: l10n.consoleLegalTitleLabel,
                ),
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              TextField(
                key: const Key('console-legal-body'),
                controller: _body,
                enabled: !_saving,
                minLines: 12,
                maxLines: null,
                maxLength: 20000,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: l10n.consoleLegalBodyLabel,
                  helperText: l10n.consoleLegalBodyHelp,
                  helperMaxLines: 3,
                  alignLabelWithHint: true,
                ),
              ),
            ],
            const SizedBox(height: TicketSurSpacing.xl),
          ],
        ),
      },
    );
  }
}
