import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _day(DateTime instant) =>
    DateFormat('d MMM y', 'fr').format(instant.toLocal());

/// Organisations de la plateforme : recherche, suspension, réactivation.
class ConsoleOrganizationsPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConsoleOrganizationsPage> createState() =>
      _ConsoleOrganizationsPageState();
}

class _ConsoleOrganizationsPageState
    extends ConsumerState<ConsoleOrganizationsPage> {
  String _search = '';
  bool _disabledOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ref.watch(adminRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.consoleNavOrganizations)),
      body: ConsolePagedList<AdminOrganization>(
        key: ValueKey(('orgs', _search, _disabledOnly)),
        load: (offset, _) => repository.organizations(
          search: _search,
          disabledOnly: _disabledOnly,
          offset: offset,
        ),
        header: Padding(
          padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConsoleSearchField(
                key: const Key('console-org-search'),
                hint: l10n.consoleSearchOrganizations,
                initial: _search,
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              FilterChip(
                key: const Key('console-org-disabled-only'),
                label: Text(l10n.consoleDisabledOnly),
                selected: _disabledOnly,
                onSelected: (value) => setState(() => _disabledOnly = value),
              ),
            ],
          ),
        ),
        itemBuilder: (context, org, reload) =>
            _OrganizationTile(organization: org, onChanged: reload),
      ),
    );
  }
}

class _OrganizationTile extends ConsumerWidget {
  const new({required this.organization, required this.onChanged});

  final AdminOrganization organization;
  final VoidCallback onChanged;

  Future<void> _act(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final org = organization;
    final reason = await showConsoleConfirm(
      context,
      title: org.active ? l10n.consoleSuspend : l10n.consoleReactivate,
      body: org.active ? l10n.consoleSuspendHint : org.name,
      confirmLabel: org.active
          ? l10n.consoleConfirmSuspend
          : l10n.consoleReactivate,
      needsReason: org.active,
      destructive: org.active,
      confirmKey: const Key('console-org-confirm'),
    );
    if (reason == null) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .setOrganizationActive(
            org.id,
            active: !org.active,
            reason: org.active ? reason : null,
          );
      toast.success(
        org.active ? l10n.consoleSuspendedDone : l10n.consoleReactivatedDone,
      );
      ref.invalidate(adminOverviewProvider);
      onChanged();
    } on Object catch (error) {
      toast.error(
        error == AdminFailure.network || error == AdminFailure.unknown
            ? l10n.consoleActionError
            : consoleFailureMessage(l10n, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final org = organization;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );
    return Card(
      key: Key('console-org-${org.id}'),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(org.name, style: textTheme.titleMedium)),
                if (!org.active)
                  ConsoleTag(label: l10n.consoleSuspended, danger: true),
              ],
            ),
            const SizedBox(height: TicketSurSpacing.xxs),
            Text(l10n.consoleOrgOwner(org.ownerName), style: muted),
            Text(l10n.consoleOrgCreated(_day(org.createdAt)), style: muted),
            Text(
              l10n.consoleOrgCounts(org.members, org.events, org.tickets),
              style: muted,
            ),
            if (!org.active && org.disabledAt != null) ...[
              const SizedBox(height: TicketSurSpacing.xs),
              Text(
                l10n.consoleSuspendedSince(
                  _day(org.disabledAt!),
                  org.disabledReason ?? '—',
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: TicketSurSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: org.active
                  ? TextButton.icon(
                      key: const Key('console-org-suspend'),
                      onPressed: () => unawaited(_act(context, ref)),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      icon: const Icon(Icons.block_rounded),
                      label: Text(l10n.consoleSuspend),
                    )
                  : FilledButton.tonalIcon(
                      key: const Key('console-org-reactivate'),
                      onPressed: () => unawaited(_act(context, ref)),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(l10n.consoleReactivate),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
