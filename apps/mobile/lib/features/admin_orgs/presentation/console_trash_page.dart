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
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/admin_accounts/domain/admin_accounts.dart';
import 'package:ticketsur/features/admin_accounts/presentation/admin_accounts_widgets.dart';
import 'package:ticketsur/features/admin_orgs/application/admin_orgs_providers.dart';
import 'package:ticketsur/features/admin_orgs/domain/admin_orgs.dart';
import 'package:ticketsur/l10n/l10n.dart';

String _day(DateTime instant) =>
    DateFormat.yMMMd(appLocaleTag).format(instant.toLocal());

/// Console : corbeille (structures supprimées depuis moins de 30 jours).
class ConsoleTrashPage extends ConsumerWidget {
  const new({super.key});

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    TrashItem item,
  ) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final result = await showAccountActionSheet(
      context,
      title: l10n.adminOrgsRestore,
      body: item.name,
      confirmLabel: l10n.adminOrgsRestore,
      notifyDefault: ref.read(adminMeProvider).value?.notifyUsers ?? false,
    );
    if (result == null) return;
    try {
      await ref
          .read(adminOrgsRepositoryProvider)
          .restore(item.id, reason: result.reason, notify: result.notify);
      toast.success(l10n.adminOrgsRestored);
      ref
        ..invalidate(consoleTrashProvider)
        ..invalidate(adminOverviewProvider);
    } on Object catch (error) {
      toast.error(adminAccountsFailureMessage(l10n, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trash = ref.watch(consoleTrashProvider);
    final me = ref.watch(adminMeProvider).value;
    final canRestore = me?.can(AdminPermission.organizations) ?? false;
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.palette.mutedText);
    final now = DateTime.now().toUtc();
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.consoleTrashTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(consoleTrashProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          children: [
            Text(l10n.consoleTrashHint, style: muted),
            const SizedBox(height: TicketSurSpacing.sm),
            switch (trash) {
              AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.all(TicketSurSpacing.lg),
                child: Text(
                  l10n.consoleTrashEmpty,
                  key: const Key('trash-empty'),
                  textAlign: TextAlign.center,
                ),
              ),
              AsyncData(:final value) => Column(
                children: [
                  for (final item in value)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: TicketSurSpacing.sm,
                      ),
                      child: TikeoCard(
                        key: Key('trash-${item.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.apartment_rounded),
                              title: Text(item.name),
                              subtitle: Text(
                                [
                                  ?item.ownerName,
                                  l10n.consoleTrashDeletedOn(
                                    _day(item.trashedAt),
                                  ),
                                  l10n.consoleTrashDaysLeft(item.daysLeft(now)),
                                ].join('\n'),
                              ),
                              isThreeLine: true,
                              onTap: () => unawaited(
                                context.push(
                                  AppRoutes.consoleOrganization(item.id),
                                ),
                              ),
                            ),
                            if (canRestore)
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: FilledButton.tonalIcon(
                                  key: Key('trash-restore-${item.id}'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                  ),
                                  onPressed: () =>
                                      unawaited(_restore(context, ref, item)),
                                  icon: const Icon(
                                    Icons.restore_from_trash_rounded,
                                  ),
                                  label: Text(l10n.adminOrgsRestore),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              AsyncError(:final error) => Text(
                adminAccountsFailureMessage(l10n, error),
                key: const Key('trash-error'),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(TicketSurSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ],
        ),
      ),
    );
  }
}
