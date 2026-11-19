import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/empty_state.dart';
import 'package:ticketsur/design_system/widgets/status_chip.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/support/application/support_providers.dart';
import 'package:ticketsur/features/support/domain/support.dart';
import 'package:ticketsur/features/support/presentation/support_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Pastille d'état d'une demande.
class SupportStatusTag extends StatelessWidget {
  const new({required this.status, super.key});

  final SupportStatus status;

  @override
  Widget build(BuildContext context) => StatusChip(
    label: supportStatusLabel(context.l10n, status),
    tone: switch (status) {
      SupportStatus.answered => StatusTone.positive,
      SupportStatus.open => StatusTone.info,
      SupportStatus.closed => StatusTone.neutral,
    },
  );
}

/// Mes demandes de support.
class SupportListPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final requests = ref.watch(mySupportRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('support-new'),
        heroTag: 'support-new',
        onPressed: () => unawaited(context.push(AppRoutes.supportNew)),
        icon: const Icon(Icons.edit_rounded),
        label: Text(l10n.supportNew),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mySupportRequestsProvider);
          try {
            await ref.read(mySupportRequestsProvider.future);
          } on Object {
            // L'échec s'affiche dans la page.
          }
        },
        child: switch (requests) {
          AsyncData(:final value) when value.isEmpty => EmptyState(
            icon: Icons.support_agent_rounded,
            title: l10n.supportEmptyTitle,
            titleKey: const Key('support-empty'),
            body: l10n.supportEmptyBody,
            scrollable: true,
          ),
          AsyncData(:final value) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              TicketSurSpacing.md,
              TicketSurSpacing.md,
              TicketSurSpacing.md,
              96,
            ),
            children: [
              for (final request in value)
                SupportRequestTile(
                  request: request,
                  onTap: () => unawaited(
                    context.push(AppRoutes.supportThread(request.id)),
                  ),
                ),
            ],
          ),
          AsyncError() => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(TicketSurSpacing.xl),
            children: [
              Text(
                l10n.supportLoadError,
                key: const Key('support-error'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// Ligne d'une demande (utilisateur ou console).
class SupportRequestTile extends StatelessWidget {
  const new({required this.request, required this.onTap, super.key});

  final SupportRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );
    return Card(
      key: Key('support-request-${request.id}'),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (request.unread)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 6,
                        right: TicketSurSpacing.xs,
                      ),
                      child: Icon(
                        Icons.circle,
                        key: Key('support-unread-${request.id}'),
                        size: 10,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      request.subject,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: request.unread ? FontWeight.w800 : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: TicketSurSpacing.xs),
                  SupportStatusTag(status: request.status),
                ],
              ),
              if (request.requesterName case final name?)
                Text(
                  l10n.consoleSupportFrom(name, request.requesterEmail ?? '—'),
                  style: textTheme.bodyMedium,
                ),
              const SizedBox(height: TicketSurSpacing.xxs),
              Text(
                [
                  supportCategoryLabel(l10n, request.category),
                  ?request.organizationName,
                  if (request.messages > 0)
                    l10n.consoleSupportMessages(request.messages),
                ].join(' · '),
                style: muted,
              ),
              Text(
                l10n.supportLastMessage(supportWhen(request.lastMessageAt)),
                style: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formulaire d'une nouvelle demande.
class NewSupportRequestPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NewSupportRequestPage> createState() =>
      _NewSupportRequestPageState();
}

class _NewSupportRequestPageState extends ConsumerState<NewSupportRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  SupportCategory _category = SupportCategory.question;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final toast = Toaster.of(context);
    try {
      final id = await ref
          .read(supportRepositoryProvider)
          .create(
            subject: _subject.text,
            category: _category,
            body: _body.text,
            organizationId: ref.read(activeOrganizationProvider)?.id,
          );
      ref.invalidate(mySupportRequestsProvider);
      if (!mounted) return;
      toast.success(l10n.supportSent);
      context.pushReplacement(AppRoutes.supportThread(id));
    } on Object catch (error) {
      if (mounted) setState(() => _error = supportFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportNew)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(TicketSurSpacing.lg),
            children: [
              if (_error case final error?) ...[
                Text(
                  error,
                  key: const Key('support-form-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: TicketSurSpacing.md),
              ],
              Text(
                l10n.supportCategoryLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              Wrap(
                spacing: TicketSurSpacing.xs,
                runSpacing: TicketSurSpacing.xs,
                children: [
                  for (final category in SupportCategory.values)
                    ChoiceChip(
                      key: Key('support-category-${category.wireName}'),
                      label: Text(supportCategoryLabel(l10n, category)),
                      selected: category == _category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                ],
              ),
              const SizedBox(height: TicketSurSpacing.md),
              TextFormField(
                key: const Key('support-subject'),
                controller: _subject,
                enabled: !_sending,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.supportSubjectLabel,
                ),
                validator: (value) => (value ?? '').trim().length < 3
                    ? l10n.supportSubjectInvalid
                    : null,
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              TextFormField(
                key: const Key('support-body'),
                controller: _body,
                enabled: !_sending,
                minLines: 5,
                maxLines: 10,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.supportBodyLabel,
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.supportBodyInvalid
                    : null,
              ),
              const SizedBox(height: TicketSurSpacing.lg),
              FilledButton.icon(
                key: const Key('support-send'),
                onPressed: _sending ? null : () => unawaited(_send()),
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(l10n.supportSend),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fil d'une demande, pour son auteur ou pour la console ([admin]).
class SupportThreadPage extends ConsumerStatefulWidget {
  const new({required this.requestId, this.admin = false, super.key});

  final String requestId;
  final bool admin;

  @override
  ConsumerState<SupportThreadPage> createState() => _SupportThreadPageState();
}

class _SupportThreadPageState extends ConsumerState<SupportThreadPage> {
  final _reply = TextEditingController();
  bool _sending = false;
  bool _closed = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _refreshLists() {
    ref
      ..invalidate(supportThreadProvider(widget.requestId))
      ..invalidate(mySupportRequestsProvider)
      ..invalidate(supportCountsProvider);
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _sending = true);
    try {
      await ref.read(supportRepositoryProvider).reply(widget.requestId, text);
      _reply.clear();
      if (mounted) setState(() => _closed = false);
      _refreshLists();
    } on Object catch (error) {
      toast.error(supportFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _close() async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    try {
      await ref.read(supportRepositoryProvider).close(widget.requestId);
      _refreshLists();
      if (!mounted) return;
      setState(() => _closed = true);
      toast.info(l10n.supportClosed);
    } on Object catch (error) {
      toast.error(supportFailureMessage(l10n, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final thread = ref.watch(supportThreadProvider(widget.requestId));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supportTitle),
        leading: BackButton(
          onPressed: () => context.popOr(
            widget.admin ? AppRoutes.consoleSupport : AppRoutes.support,
          ),
        ),
        actions: [
          if (!_closed)
            IconButton(
              key: const Key('support-close'),
              tooltip: l10n.supportClose,
              onPressed: () => unawaited(_close()),
              icon: const Icon(Icons.task_alt_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: switch (thread) {
              AsyncData(:final value) => ListView(
                key: const Key('support-thread'),
                padding: const EdgeInsets.all(TicketSurSpacing.md),
                children: [
                  for (final message in value)
                    _Bubble(
                      message: message,
                      mine: widget.admin
                          ? message.fromAdmin
                          : !message.fromAdmin,
                    ),
                ],
              ),
              AsyncError(:final error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(TicketSurSpacing.xl),
                  child: Text(
                    supportFailureMessage(l10n, error),
                    key: const Key('support-thread-error'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TicketSurSpacing.md,
                TicketSurSpacing.xs,
                TicketSurSpacing.xs,
                TicketSurSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('support-reply'),
                      controller: _reply,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n.supportReplyHint,
                        counterText: '',
                      ),
                    ),
                  ),
                  IconButton.filled(
                    key: const Key('support-reply-send'),
                    tooltip: l10n.supportSend,
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: _sending ? null : () => unawaited(_send()),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const new({required this.message, required this.mine});

  final SupportMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final background = mine
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh;
    final foreground = mine ? scheme.onPrimaryContainer : scheme.onSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          key: Key('support-message-${message.id}'),
          margin: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
          padding: const EdgeInsets.all(TicketSurSpacing.sm),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(TicketSurRadii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.authorName,
                style: textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: TicketSurSpacing.xxs),
              Text(
                message.body,
                style: textTheme.bodyMedium?.copyWith(color: foreground),
              ),
              const SizedBox(height: TicketSurSpacing.xxs),
              Text(
                supportWhen(message.createdAt),
                style: textTheme.labelSmall?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
