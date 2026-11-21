import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Console : réglages (super administrateur) et liste des administrateurs.
class ConsoleSettingsPage extends ConsumerWidget {
  const new({super.key});

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    bool? notifyUsers,
    bool? adminIssueTickets,
  }) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    try {
      await ref
          .read(adminAccountsRepositoryProvider)
          .saveSettings(
            notifyUsers: notifyUsers,
            adminIssueTickets: adminIssueTickets,
          );
      ref.invalidate(adminMeProvider);
      toast.success(l10n.consoleSettingsSaved);
    } on Object catch (error) {
      toast.error(adminAccountsFailureMessage(l10n, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final me = ref.watch(adminMeProvider).value;
    final admins = ref.watch(platformAdminsProvider);
    final editable = me?.can(AdminPermission.settings) ?? false;
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.consoleSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: [
          if (me != null)
            TikeoCard(
              key: const Key('console-my-role'),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_rounded),
                title: Text(l10n.consoleMyRole(adminRoleLabel(l10n, me.role))),
                subtitle: Text(adminRoleHint(l10n, me.role)),
              ),
            ),
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.consoleSettingsTitle, style: textTheme.titleMedium),
                if (!editable)
                  Text(
                    l10n.consoleSettingsReadOnly,
                    style: textTheme.bodySmall,
                  ),
                SwitchListTile(
                  key: const Key('console-setting-notify'),
                  contentPadding: EdgeInsets.zero,
                  value: me?.notifyUsers ?? false,
                  onChanged: editable
                      ? (value) =>
                            unawaited(_save(context, ref, notifyUsers: value))
                      : null,
                  title: Text(l10n.consoleSettingNotify),
                  subtitle: Text(l10n.consoleSettingNotifyHint),
                ),
                SwitchListTile(
                  key: const Key('console-setting-issue'),
                  contentPadding: EdgeInsets.zero,
                  value: me?.adminIssueTickets ?? false,
                  onChanged: editable
                      ? (value) => unawaited(
                          _save(context, ref, adminIssueTickets: value),
                        )
                      : null,
                  title: Text(l10n.consoleSettingIssue),
                  subtitle: Text(l10n.consoleSettingIssueHint),
                ),
              ],
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            key: const Key('console-admins'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.consoleAdminsTitle, style: textTheme.titleMedium),
                Text(l10n.consoleAdminsHint, style: textTheme.bodySmall),
                switch (admins) {
                  AsyncData(:final value) => Column(
                    children: [
                      for (final admin in value)
                        ListTile(
                          key: Key('console-admin-${admin.id}'),
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            admin.mfaEnrolled
                                ? Icons.verified_user_rounded
                                : Icons.person_rounded,
                          ),
                          title: Text(admin.displayName),
                          subtitle: Text(
                            [
                              adminRoleLabel(l10n, admin.role),
                              ?admin.email,
                            ].join(' · '),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => unawaited(
                            context.push(AppRoutes.consoleAccount(admin.id)),
                          ),
                        ),
                    ],
                  ),
                  AsyncError(:final error) => Text(
                    adminAccountsFailureMessage(l10n, error),
                  ),
                  _ => const Padding(
                    padding: EdgeInsets.all(TicketSurSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }
}
