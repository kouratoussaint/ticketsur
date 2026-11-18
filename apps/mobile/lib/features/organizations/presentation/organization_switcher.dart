import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Choix de l'organisation active (S05), en feuille du bas.
Future<void> showOrganizationSwitcher(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const OrganizationSwitcherSheet(),
    );

/// Contenu de la feuille de choix d'organisation.
class OrganizationSwitcherSheet extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(organizationsProvider).value;
    final active = state?.active;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: TicketSurSpacing.md),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TicketSurSpacing.lg),
          child: Text(
            l10n.orgSwitchTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: TicketSurSpacing.sm),
        for (final organization in state?.all ?? const <Organization>[])
          ListTile(
            key: Key('org-option-${organization.slug}'),
            leading: Icon(
              organization.id == active?.id
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(organization.name),
            subtitle: Text(roleLabel(l10n, organization.role)),
            selected: organization.id == active?.id,
            onTap: () async {
              await ref
                  .read(organizationsProvider.notifier)
                  .select(organization);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        const Divider(),
        ListTile(
          key: const Key('org-create-another'),
          leading: const Icon(Icons.add_business_rounded),
          title: Text(l10n.orgCreateAction),
          onTap: () {
            Navigator.of(context).pop();
            unawaited(context.push(AppRoutes.newOrganization));
          },
        ),
      ],
    );
  }
}
