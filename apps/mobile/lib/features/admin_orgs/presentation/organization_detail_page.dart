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
import 'package:ticketsur/design_system/widgets/cached_network_image.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/features/admin/presentation/audit_labels.dart';
import 'package:ticketsur/features/admin/presentation/console_widgets.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/features/admin_orgs/application/admin_orgs_providers.dart';
import 'package:ticketsur/features/admin_orgs/domain/admin_orgs.dart';
import 'package:ticketsur/features/admin_orgs/presentation/account_picker.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart'
    show MemberRole;
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _day(DateTime instant) =>
    DateFormat.yMMMd(appLocaleTag).format(instant.toLocal());

String _when(DateTime instant) => formatDateAtTime(instant.toLocal());

/// Console : fiche complète d'une structure et actions (lot 4-11b,
/// ADR 0039).
class OrganizationDetailPage extends ConsumerWidget {
  const new({required this.organizationId, super.key});

  final String organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(organizationDetailProvider(organizationId));
    return Scaffold(
      appBar: TikeoAppBar(
        title: Text(detail.value?.name ?? l10n.adminOrgsTitle),
      ),
      body: switch (detail) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(organizationDetailProvider(organizationId).future),
          child: _Detail(organization: value),
        ),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  adminAccountsFailureMessage(l10n, error),
                  key: const Key('org-error'),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(
                    organizationDetailProvider(organizationId),
                  ),
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
  const new({required this.organization});

  final OrganizationDetail organization;

  /// Lance une action, puis relit la fiche, la vue d'ensemble et la
  /// corbeille.
  Future<bool> _run(
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
        ..invalidate(organizationDetailProvider(organization.id))
        ..invalidate(adminOverviewProvider)
        ..invalidate(consoleTrashProvider);
      return true;
    } on Object catch (error) {
      toast.error(
        error is AdminFailure
            ? consoleFailureMessage(l10n, error)
            : adminAccountsFailureMessage(l10n, error),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final org = organization;
    final me = ref.watch(adminMeProvider).value;
    final orgs = ref.read(adminOrgsRepositoryProvider);
    final notify = me?.notifyUsers ?? false;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.palette.mutedText,
    );
    final canManage = me?.can(AdminPermission.organizations) ?? false;
    final canDelete = me?.can(AdminPermission.organizationsDelete) ?? false;
    final canStatus = me?.can(AdminPermission.orgStatus) ?? false;

    String? nameCheck(String value) =>
        value.trim().toLowerCase() == org.name.toLowerCase()
        ? null
        : l10n.adminOrgsErrorConfirmName;

    Future<void> edit() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminOrgsEdit,
        confirmLabel: l10n.profileSave,
        notifyDefault: notify,
        fields: [
          ActionField(
            name: 'name',
            label: l10n.adminOrgsName,
            initial: org.name,
            validator: (value) => value.length < 2 || value.length > 120
                ? l10n.adminOrgsErrorName
                : null,
          ),
          ActionField(
            name: 'city',
            label: l10n.adminOrgsCity,
            initial: org.city,
            required: false,
          ),
          ActionField(
            name: 'phone',
            label: l10n.adminOrgsPhone,
            initial: org.phone,
            keyboard: TextInputType.phone,
            required: false,
          ),
          ActionField(
            name: 'email',
            label: l10n.adminOrgsContactEmail,
            initial: org.contactEmail,
            keyboard: TextInputType.emailAddress,
            required: false,
          ),
          ActionField(
            name: 'public_phone',
            label: l10n.adminOrgsPublicPhone,
            initial: org.publicPhone,
            keyboard: TextInputType.phone,
            required: false,
          ),
        ],
      );
      if (result == null || !context.mounted) return;
      String? optional(String key) =>
          result.fields[key]!.isEmpty ? null : result.fields[key];
      await _run(context, ref, () async {
        await orgs.update(
          org.id,
          name: result.fields['name']!,
          city: optional('city'),
          phone: optional('phone'),
          contactEmail: optional('email'),
          publicPhone: optional('public_phone'),
          reason: result.reason,
          notify: result.notify,
        );
        return l10n.adminOrgsUpdated;
      });
    }

    Future<void> removeLogo() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminOrgsRemoveLogo,
        body: l10n.adminOrgsRemoveLogoHint,
        confirmLabel: l10n.adminOrgsRemoveLogo,
        notifyDefault: notify,
        destructive: true,
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        await orgs.removeLogo(
          org.id,
          reason: result.reason,
          notify: result.notify,
        );
        return l10n.adminOrgsLogoRemoved;
      });
    }

    Future<void> setStatus() async {
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
      if (reason == null || !context.mounted) return;
      await _run(context, ref, () async {
        await ref
            .read(adminRepositoryProvider)
            .setOrganizationActive(
              org.id,
              active: !org.active,
              reason: org.active ? reason : null,
            );
        return org.active
            ? l10n.consoleSuspendedDone
            : l10n.consoleReactivatedDone;
      });
    }

    Future<void> addMember() async {
      final added = await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _AddMemberSheet(organization: org),
      );
      if (added ?? false) {
        ref.invalidate(organizationDetailProvider(org.id));
      }
    }

    Future<void> delete() async {
      final toast = Toaster.of(context);
      OrgDeletePreview preview;
      try {
        preview = await orgs.deletePreview(org.id);
      } on Object catch (error) {
        toast.error(adminAccountsFailureMessage(l10n, error));
        return;
      }
      if (!context.mounted) return;
      final body = preview.trash
          ? l10n.adminOrgsDeleteTrashHint
          : [
              l10n.adminOrgsDeleteCloseHint,
              l10n.adminOrgsPreviewEvents(preview.eventsToCancel),
              l10n.adminOrgsPreviewTickets(preview.ticketsToCancel),
              l10n.adminOrgsPreviewHolders(preview.holdersToNotify),
            ].join('\n');
      final result = await showAccountActionSheet(
        context,
        title: preview.trash
            ? l10n.adminOrgsDeleteTrashTitle
            : l10n.adminOrgsDeleteCloseTitle,
        body: '$body\n\n${l10n.adminOrgsConfirmNameHint(org.name)}',
        confirmLabel: l10n.adminOrgsDelete,
        notifyDefault: notify,
        destructive: true,
        fields: [
          ActionField(
            name: 'confirm',
            label: l10n.adminOrgsConfirmName,
            validator: nameCheck,
          ),
        ],
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        final outcome = await orgs.delete(
          org.id,
          confirmName: result.fields['confirm']!,
          reason: result.reason,
          notify: result.notify,
        );
        return outcome.trash
            ? l10n.adminOrgsTrashed
            : l10n.adminOrgsClosed(outcome.ticketsCancelled);
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
        await orgs.restore(
          org.id,
          reason: result.reason,
          notify: result.notify,
        );
        return l10n.adminOrgsRestored;
      });
    }

    Future<void> purge() async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminOrgsPurge,
        body:
            '${l10n.adminOrgsPurgeHint}\n\n'
            '${l10n.adminOrgsConfirmNameHint(org.name)}',
        confirmLabel: l10n.adminOrgsPurge,
        destructive: true,
        fields: [
          ActionField(
            name: 'confirm',
            label: l10n.adminOrgsConfirmName,
            validator: nameCheck,
          ),
        ],
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        await orgs.purgeNow(
          org.id,
          confirmName: result.fields['confirm']!,
          reason: result.reason,
        );
        return l10n.adminOrgsPurged;
      });
    }

    final actions = <Widget>[
      if (org.editable && canManage) ...[
        OutlinedButton.icon(
          key: const Key('org-edit'),
          onPressed: () => unawaited(edit()),
          icon: const Icon(Icons.edit_rounded),
          label: Text(l10n.adminOrgsEdit),
        ),
        OutlinedButton.icon(
          key: const Key('org-add-member'),
          onPressed: () => unawaited(addMember()),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(l10n.adminOrgsAddMember),
        ),
        if (org.logoPath != null)
          OutlinedButton.icon(
            key: const Key('org-remove-logo'),
            onPressed: () => unawaited(removeLogo()),
            icon: const Icon(Icons.hide_image_rounded),
            label: Text(l10n.adminOrgsRemoveLogo),
          ),
      ],
      if (org.editable && canStatus)
        OutlinedButton.icon(
          key: Key(org.active ? 'org-suspend' : 'org-reactivate'),
          onPressed: () => unawaited(setStatus()),
          icon: Icon(
            org.active ? Icons.block_rounded : Icons.restart_alt_rounded,
          ),
          label: Text(
            org.active ? l10n.consoleSuspend : l10n.consoleReactivate,
          ),
        ),
      if (org.trashed && canManage)
        FilledButton.icon(
          key: const Key('org-restore'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => unawaited(restore()),
          icon: const Icon(Icons.restore_from_trash_rounded),
          label: Text(l10n.adminOrgsRestore),
        ),
      if (canDelete && (org.editable || org.trashed))
        FilledButton.icon(
          key: Key(org.trashed ? 'org-purge' : 'org-delete'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => unawaited(org.trashed ? purge() : delete()),
          icon: const Icon(Icons.delete_forever_rounded),
          label: Text(org.trashed ? l10n.adminOrgsPurge : l10n.adminOrgsDelete),
        ),
    ];

    Future<void> memberActions(OrgMember member) async {
      final action = await showModalBottomSheet<String>(
        context: context,
        useRootNavigator: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(member.displayName),
                subtitle: Text(roleLabel(l10n, member.role)),
              ),
              ListTile(
                key: const Key('member-action-open'),
                leading: const Icon(Icons.manage_accounts_rounded),
                title: Text(l10n.adminAccountsOpen),
                onTap: () => Navigator.of(context).pop('open'),
              ),
              if (org.editable &&
                  canManage &&
                  member.active &&
                  member.role != MemberRole.owner) ...[
                ListTile(
                  key: const Key('member-action-role'),
                  leading: const Icon(Icons.swap_horiz_rounded),
                  title: Text(
                    member.role == MemberRole.manager
                        ? l10n.adminOrgsMakeController
                        : l10n.adminOrgsMakeManager,
                  ),
                  onTap: () => Navigator.of(context).pop('role'),
                ),
                ListTile(
                  key: const Key('member-action-transfer'),
                  leading: const Icon(Icons.vpn_key_rounded),
                  title: Text(l10n.adminOrgsTransfer),
                  onTap: () => Navigator.of(context).pop('transfer'),
                ),
                ListTile(
                  key: const Key('member-action-remove'),
                  leading: const Icon(Icons.person_remove_rounded),
                  title: Text(l10n.adminOrgsRemoveMember),
                  onTap: () => Navigator.of(context).pop('remove'),
                ),
              ],
            ],
          ),
        ),
      );
      if (action == null || !context.mounted) return;
      switch (action) {
        case 'open':
          unawaited(context.push(AppRoutes.consoleAccount(member.userId)));
        case 'role':
          final role = member.role == MemberRole.manager
              ? MemberRole.controller
              : MemberRole.manager;
          final result = await showAccountActionSheet(
            context,
            title: role == MemberRole.manager
                ? l10n.adminOrgsMakeManager
                : l10n.adminOrgsMakeController,
            confirmLabel: l10n.profileSave,
            notifyDefault: notify,
          );
          if (result == null || !context.mounted) return;
          await _run(context, ref, () async {
            await orgs.setMemberRole(
              org.id,
              member.userId,
              role,
              reason: result.reason,
              notify: result.notify,
            );
            return l10n.adminOrgsRoleChanged;
          });
        case 'transfer':
          final result = await showAccountActionSheet(
            context,
            title: l10n.adminOrgsTransfer,
            body: l10n.adminOrgsTransferHint(member.displayName),
            confirmLabel: l10n.adminOrgsTransfer,
          );
          if (result == null || !context.mounted) return;
          await _run(context, ref, () async {
            await ref
                .read(adminRepositoryProvider)
                .assignOrganization(
                  member.userId,
                  organizationId: org.id,
                  role: MemberRole.owner,
                  reason: result.reason,
                );
            return l10n.adminOrgsTransferred;
          });
        case 'remove':
          final result = await showAccountActionSheet(
            context,
            title: l10n.adminOrgsRemoveMember,
            body: member.displayName,
            confirmLabel: l10n.adminOrgsRemoveMember,
            notifyDefault: notify,
            destructive: true,
          );
          if (result == null || !context.mounted) return;
          await _run(context, ref, () async {
            await orgs.removeMember(
              org.id,
              member.userId,
              reason: result.reason,
              notify: result.notify,
            );
            return l10n.adminOrgsMemberRemoved;
          });
      }
    }

    Future<void> revokeInvitation(OrgInvitationSummary invitation) async {
      final result = await showAccountActionSheet(
        context,
        title: l10n.adminOrgsRevokeInvitation,
        confirmLabel: l10n.adminOrgsRevokeInvitation,
        destructive: true,
      );
      if (result == null || !context.mounted) return;
      await _run(context, ref, () async {
        await orgs.revokeInvitation(invitation.id, reason: result.reason);
        return l10n.adminOrgsInvitationRevoked;
      });
    }

    // Tout est construit (fiche de taille raisonnable) : tirer pour
    // actualiser reste possible.
    return SingleChildScrollView(
      key: const Key('org-detail'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TikeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (org.logoPath case final path?) ...[
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: networkImage(
                          orgs.logoUrl(path),
                          cacheWidth: 96,
                        ),
                      ),
                      const SizedBox(width: TicketSurSpacing.sm),
                    ],
                    Expanded(
                      child: Text(org.name, style: textTheme.titleLarge),
                    ),
                  ],
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                Wrap(
                  spacing: TicketSurSpacing.xxs,
                  runSpacing: TicketSurSpacing.xxs,
                  children: [
                    if (org.purged)
                      ConsoleTag(label: l10n.adminOrgsPurgedTag, danger: true)
                    else if (org.closed)
                      ConsoleTag(
                        key: const Key('org-tag-closed'),
                        label: l10n.adminOrgsClosedTag,
                        danger: true,
                      )
                    else if (org.trashed)
                      ConsoleTag(
                        key: const Key('org-tag-trashed'),
                        label: l10n.adminOrgsTrashedTag,
                        danger: true,
                      )
                    else if (!org.active)
                      ConsoleTag(
                        key: const Key('org-tag-suspended'),
                        label: l10n.consoleSuspended,
                        danger: true,
                      ),
                    if (org.packName case final pack?)
                      ConsoleTag(label: pack, danger: false),
                  ],
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                Text(l10n.consoleOrgCreated(_day(org.createdAt)), style: muted),
                if (org.city case final city?) Text(city, style: muted),
                if (org.phone case final phone?)
                  Text(l10n.adminOrgsPhoneValue(phone), style: muted),
                if (org.publicPhone case final phone?)
                  Text(l10n.adminOrgsPublicPhoneValue(phone), style: muted),
                if (org.contactEmail case final email?)
                  Text(email, style: muted),
                if (!org.active && org.disabledReason != null && !org.purged)
                  Text(
                    l10n.adminAccountsReasonValue(org.disabledReason!),
                    style: muted,
                  ),
                if (org.trashed && org.purgeDueAt != null)
                  Text(
                    l10n.adminOrgsPurgeOn(_day(org.purgeDueAt!)),
                    key: const Key('org-purge-due'),
                    style: muted,
                  ),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: TicketSurSpacing.md),
            TikeoCard(
              key: const Key('org-actions'),
              child: Wrap(
                spacing: TicketSurSpacing.xs,
                runSpacing: TicketSurSpacing.xs,
                children: actions,
              ),
            ),
          ],
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            key: const Key('org-owner'),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.vpn_key_rounded),
              title: Text(l10n.adminOrgsOwnerValue(org.ownerName)),
              subtitle: Text(org.ownerEmail ?? '—'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: org.ownerId.isEmpty
                  ? null
                  : () => unawaited(
                      context.push(AppRoutes.consoleAccount(org.ownerId)),
                    ),
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            key: const Key('org-activity'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.adminAccountsActivity, style: textTheme.titleMedium),
                const SizedBox(height: TicketSurSpacing.xs),
                Text(
                  l10n.adminOrgsEventsCount(
                    org.eventsTotal,
                    org.eventsUpcoming,
                  ),
                ),
                Text(
                  l10n.adminOrgsTicketsCount(
                    org.ticketsIssued,
                    org.ticketsAdmitted,
                  ),
                ),
                Text(
                  l10n.adminOrgsInvoicesCount(org.invoices, org.invoicesDue),
                ),
              ],
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          _Section(
            key: const Key('org-members'),
            title: l10n.adminOrgsMembers,
            empty: l10n.adminOrgsNoMember,
            children: [
              for (final member in org.members)
                ListTile(
                  key: Key('org-member-${member.userId}'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(roleIcon(member.role)),
                  title: Text(member.displayName),
                  subtitle: Text(
                    [
                      roleLabel(l10n, member.role),
                      ?member.email,
                      if (!member.active) l10n.adminAccountsMemberInactive,
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.more_vert_rounded),
                  onTap: () => unawaited(memberActions(member)),
                ),
            ],
          ),
          if (org.invitations.isNotEmpty) ...[
            const SizedBox(height: TicketSurSpacing.md),
            _Section(
              key: const Key('org-invitations'),
              title: l10n.adminOrgsInvitations,
              empty: '',
              children: [
                for (final invitation in org.invitations)
                  ListTile(
                    key: Key('org-invitation-${invitation.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_rounded),
                    title: Text('•••• ${invitation.codeHint}'),
                    subtitle: Text(
                      [
                        roleLabel(l10n, invitation.role),
                        l10n.adminOrgsInvitationUntil(
                          _day(invitation.expiresAt),
                        ),
                      ].join(' · '),
                    ),
                    trailing: org.editable && canManage
                        ? IconButton(
                            key: Key('org-invitation-revoke-${invitation.id}'),
                            tooltip: l10n.adminOrgsRevokeInvitation,
                            onPressed: () =>
                                unawaited(revokeInvitation(invitation)),
                            icon: const Icon(Icons.block_rounded),
                          )
                        : null,
                  ),
              ],
            ),
          ],
          const SizedBox(height: TicketSurSpacing.md),
          _Section(
            key: const Key('org-events'),
            title: l10n.adminOrgsEvents,
            empty: l10n.adminOrgsNoEvent,
            children: [
              for (final event in org.events)
                ListTile(
                  key: Key('org-event-${event.id}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      unawaited(context.push(AppRoutes.consoleEvent(event.id))),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_rounded),
                  title: Text(event.title),
                  subtitle: Text(
                    [
                      _day(event.startsAt),
                      eventStatusLabel(l10n, event.status),
                      l10n.adminOrgsEventTickets(event.tickets, event.admitted),
                    ].join(' · '),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.md),
          _Section(
            key: const Key('org-history'),
            title: l10n.adminAccountsHistory,
            empty: l10n.adminOrgsNoHistory,
            children: [
              for (final action in org.actions)
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
          const SizedBox(height: TicketSurSpacing.xl),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const new({
    required this.title,
    required this.empty,
    required this.children,
    super.key,
  });

  final String title;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => TikeoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TicketSurSpacing.xs),
        if (children.isEmpty)
          Text(empty, style: TextStyle(color: context.palette.mutedText))
        else
          ...children,
      ],
    ),
  );
}

/// Ajouter un compte existant à la structure (gestionnaire ou contrôleur).
class _AddMemberSheet extends ConsumerStatefulWidget {
  const new({required this.organization});

  final OrganizationDetail organization;

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  AdminAccount? _account;
  MemberRole _role = MemberRole.controller;
  final _reason = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final account = _account;
    if (account == null) {
      setState(() => _error = l10n.adminOrgsPickAccount);
      return;
    }
    if (_reason.text.trim().length < 3) {
      setState(() => _error = l10n.adminAccountsErrorReason);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminRepositoryProvider)
          .assignOrganization(
            account.id,
            organizationId: widget.organization.id,
            role: _role,
            reason: _reason.text.trim(),
          );
      if (!mounted) return;
      Toaster.of(context).success(l10n.adminOrgsMemberAdded);
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error is AdminFailure
              ? consoleFailureMessage(l10n, error)
              : adminAccountsFailureMessage(l10n, error);
        });
      }
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
          key: const Key('add-member-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.adminOrgsAddMember,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            AccountPicker(
              keyPrefix: 'add-member',
              picked: _account,
              onPicked: (account) => setState(() => _account = account),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            SegmentedButton<MemberRole>(
              segments: [
                ButtonSegment(
                  value: MemberRole.manager,
                  label: Text(
                    roleLabel(l10n, MemberRole.manager),
                    key: const Key('add-member-role-manager'),
                  ),
                ),
                ButtonSegment(
                  value: MemberRole.controller,
                  label: Text(
                    roleLabel(l10n, MemberRole.controller),
                    key: const Key('add-member-role-controller'),
                  ),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (roles) =>
                  setState(() => _role = roles.first),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            TextField(
              key: const Key('add-member-reason'),
              controller: _reason,
              maxLength: 500,
              decoration: InputDecoration(labelText: l10n.adminAccountsReason),
            ),
            if (_error case final error?)
              Text(
                error,
                key: const Key('add-member-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: TicketSurSpacing.sm),
            FilledButton(
              key: const Key('add-member-submit'),
              onPressed: _busy ? null : () => unawaited(_submit()),
              child: Text(l10n.adminOrgsAddMember),
            ),
          ],
        ),
      ),
    );
  }
}
