import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/empty_state.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/support/application/support_providers.dart';
import 'package:ticketsur/features/support/domain/support.dart';
import 'package:ticketsur/features/support/presentation/support_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Réponses types de la console.
final FutureProvider<List<SupportTemplate>> supportTemplatesProvider =
    FutureProvider.autoDispose<List<SupportTemplate>>(
      (ref) => ref.read(supportRepositoryProvider).templates(),
      retry: (retryCount, error) => null,
    );

/// Texte du champ après insertion de [body] : remplace un champ vide,
/// sinon s'ajoute après une ligne vide.
String insertTemplate(String current, String body) =>
    current.trim().isEmpty ? body : '${current.trimRight()}\n\n$body';

/// Feuille de choix d'une réponse type ; renvoie son texte.
Future<String?> pickSupportTemplate(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _TemplatePicker(),
    );

class _TemplatePicker extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final templates = ref.watch(supportTemplatesProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          key: const Key('support-templates-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TicketSurSpacing.md,
              ),
              child: Text(
                l10n.supportTemplatesTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: switch (templates) {
                AsyncData(:final value) when value.isEmpty => Padding(
                  padding: const EdgeInsets.all(TicketSurSpacing.md),
                  child: Text(
                    l10n.supportTemplatesEmpty,
                    key: const Key('support-templates-empty'),
                  ),
                ),
                AsyncData(:final value) => ListView(
                  shrinkWrap: true,
                  children: [
                    for (final template in value)
                      ListTile(
                        key: Key('support-template-${template.id}'),
                        leading: const Icon(Icons.quickreply_rounded),
                        title: Text(template.title),
                        subtitle: Text(
                          template.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(template.body),
                      ),
                  ],
                ),
                AsyncError(:final error) => Padding(
                  padding: const EdgeInsets.all(TicketSurSpacing.md),
                  child: Text(supportFailureMessage(l10n, error)),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(TicketSurSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
            ),
            TextButton.icon(
              key: const Key('support-templates-manage'),
              onPressed: () {
                Navigator.of(context).pop();
                unawaited(
                  GoRouter.of(context).push(AppRoutes.consoleSupportTemplates),
                );
              },
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(l10n.supportTemplatesManage),
            ),
          ],
        ),
      ),
    );
  }
}

/// Console : réponses types du support (titre et texte).
class SupportTemplatesPage extends ConsumerWidget {
  const new({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    SupportTemplate? template,
  ]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _TemplateSheet(template: template),
    );
    if (saved ?? false) ref.invalidate(supportTemplatesProvider);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SupportTemplate template,
  ) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.supportTemplateDelete),
        content: Text(template.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            key: const Key('support-template-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.supportTemplateDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(supportRepositoryProvider).deleteTemplate(template.id);
      ref.invalidate(supportTemplatesProvider);
      toast.success(l10n.supportTemplateDeleted);
    } on Object catch (error) {
      toast.error(supportFailureMessage(l10n, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final templates = ref.watch(supportTemplatesProvider);
    final count = templates.value?.length ?? 0;
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.supportTemplatesTitle)),
      floatingActionButton: count >= maxSupportTemplates
          ? null
          : FloatingActionButton.extended(
              key: const Key('support-template-new'),
              heroTag: 'support-template-new',
              onPressed: () => unawaited(_edit(context, ref)),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.supportTemplateNew),
            ),
      body: switch (templates) {
        AsyncData(:final value) when value.isEmpty => EmptyState(
          key: const Key('support-templates-page-empty'),
          icon: Icons.quickreply_rounded,
          title: l10n.supportTemplatesEmpty,
          body: l10n.supportTemplatesHelp,
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.fromLTRB(
            TicketSurSpacing.md,
            TicketSurSpacing.md,
            TicketSurSpacing.md,
            96,
          ),
          children: [
            Text(
              l10n.supportTemplatesHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            for (final template in value)
              Card(
                key: Key('support-template-row-${template.id}'),
                child: ListTile(
                  title: Text(template.title),
                  subtitle: Text(
                    template.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => unawaited(_edit(context, ref, template)),
                  trailing: IconButton(
                    key: Key('support-template-delete-${template.id}'),
                    tooltip: l10n.supportTemplateDelete,
                    icon: const Icon(Icons.delete_rounded),
                    onPressed: () => unawaited(_delete(context, ref, template)),
                  ),
                ),
              ),
          ],
        ),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.lg),
            child: Text(
              supportFailureMessage(l10n, error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _TemplateSheet extends ConsumerStatefulWidget {
  const new({this.template});

  final SupportTemplate? template;

  @override
  ConsumerState<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends ConsumerState<_TemplateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.template?.title);
  late final _body = TextEditingController(text: widget.template?.body);
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(supportRepositoryProvider)
          .saveTemplate(
            id: widget.template?.id,
            title: _title.text,
            body: _body.text,
          );
      toast.success(l10n.supportTemplateSaved);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      toast.error(supportFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _saving = false);
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.template == null
                    ? l10n.supportTemplateNew
                    : l10n.supportTemplateEdit,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: TicketSurSpacing.md),
              TextFormField(
                key: const Key('support-template-title'),
                controller: _title,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.supportTemplateTitleLabel,
                ),
                validator: (value) {
                  final length = (value ?? '').trim().length;
                  return length < 2 || length > 60
                      ? l10n.supportTemplateTitleInvalid
                      : null;
                },
              ),
              TextFormField(
                key: const Key('support-template-body'),
                controller: _body,
                minLines: 4,
                maxLines: 10,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.supportTemplateBodyLabel,
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.supportTemplateBodyInvalid
                    : null,
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              FilledButton(
                key: const Key('support-template-save'),
                onPressed: _saving ? null : () => unawaited(_save()),
                child: Text(l10n.profileSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
