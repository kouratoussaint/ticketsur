import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_orgs/presentation/create_organization_page.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _day(DateTime instant) =>
    DateFormat.yMMMd(appLocaleTag).format(instant.toLocal());

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
  int _generation = 0;
  bool _selecting = false;

  /// Créer une structure, puis ouvrir sa fiche (lot 4-11b).
  Future<void> _create() async {
    final router = GoRouter.of(context);
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CreateOrganizationPage()),
    );
    if (id == null || !mounted) return;
    setState(() {
      _generation++;
      _selecting = false;
    });
    unawaited(router.push(AppRoutes.consoleOrganization(id)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repository = ref.watch(adminRepositoryProvider);
    final canCreate =
        ref.watch(adminMeProvider).value?.can(AdminPermission.organizations) ??
        false;
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.consoleNavOrganizations)),
      // Caché en mode sélection : la barre d'actions est en bas.
      floatingActionButton: canCreate && !_selecting
          ? FloatingActionButton.extended(
              key: const Key('console-org-create'),
              heroTag: 'console-org-create',
              onPressed: () => unawaited(_create()),
              icon: const Icon(Icons.add_business_rounded),
              label: Text(l10n.adminOrgsCreate),
            )
          : null,
      body: ConsolePagedList<AdminOrganization>(
        key: ValueKey(('orgs', _search, _disabledOnly, _generation)),
        onSelectingChanged: (selecting) =>
            setState(() => _selecting = selecting),
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
                onChanged: (value) => setState(() {
                  _search = value;
                  _selecting = false;
                }),
              ),
              const SizedBox(height: TicketSurSpacing.xs),
              FilterChip(
                key: const Key('console-org-disabled-only'),
                label: Text(l10n.consoleDisabledOnly),
                selected: _disabledOnly,
                onSelected: (value) => setState(() {
                  _disabledOnly = value;
                  _selecting = false;
                }),
              ),
            ],
          ),
        ),
        itemBuilder: (context, org, reload) =>
            _OrganizationTile(organization: org, onChanged: reload),
        idOf: (org) => org.id,
        bulkActions: [
          ConsoleBulkAction(
            key: const Key('console-orgs-bulk-suspend'),
            icon: Icons.block_rounded,
            label: l10n.consoleSuspend,
            danger: true,
            run: (context, items, started) => refreshOverviewAfter(
              ref,
              runConsoleBulk(
                context,
                items: items,
                onStarted: started,
                applies: (org) => org.active,
                noneMessage: l10n.consoleBulkOrgsSuspendNone,
                title: l10n.consoleBulkOrgsSuspendTitle,
                body: l10n.consoleSuspendHint,
                confirmLabel: l10n.consoleConfirmSuspend,
                confirmKey: const Key('console-bulk-confirm'),
                needsReason: true,
                destructive: true,
                act: (org, reason) => repository.setOrganizationActive(
                  org.id,
                  active: false,
                  reason: reason,
                ),
                doneMessage: l10n.consoleBulkOrgsSuspended,
              ),
            ),
          ),
          ConsoleBulkAction(
            key: const Key('console-orgs-bulk-reactivate'),
            icon: Icons.restart_alt_rounded,
            label: l10n.consoleReactivate,
            run: (context, items, started) => refreshOverviewAfter(
              ref,
              runConsoleBulk(
                context,
                items: items,
                onStarted: started,
                applies: (org) => !org.active && org.closedAt == null,
                noneMessage: l10n.consoleBulkOrgsReactivateNone,
                title: l10n.consoleBulkOrgsReactivateTitle,
                body: l10n.consoleBulkReactivateBody,
                confirmLabel: l10n.consoleReactivate,
                confirmKey: const Key('console-bulk-confirm'),
                act: (org, _) =>
                    repository.setOrganizationActive(org.id, active: true),
                doneMessage: l10n.consoleBulkOrgsReactivated,
              ),
            ),
          ),
        ],
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
                if (org.closedAt != null)
                  ConsoleTag(
                    key: Key('console-org-closed-${org.id}'),
                    label: l10n.adminOrgsClosedTag,
                    danger: true,
                  )
                else if (!org.active)
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: TicketSurSpacing.xs,
              runSpacing: TicketSurSpacing.xs,
              children: [
                // Fiche complète de la structure (lot 4-11b).
                TextButton.icon(
                  key: Key('console-org-open-${org.id}'),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: () async {
                    await context.push(AppRoutes.consoleOrganization(org.id));
                    onChanged();
                  },
                  icon: const Icon(Icons.apartment_rounded),
                  label: Text(l10n.adminOrgsOpen),
                ),
                if (org.closedAt == null) _statusButton(context, ref),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final org = organization;
    return org.active
        ? TextButton.icon(
            key: const Key('console-org-suspend'),
            onPressed: () => unawaited(_act(context, ref)),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.block_rounded),
            label: Text(l10n.consoleSuspend),
          )
        : FilledButton.tonalIcon(
            key: const Key('console-org-reactivate'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => unawaited(_act(context, ref)),
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l10n.consoleReactivate),
          );
  }
}
