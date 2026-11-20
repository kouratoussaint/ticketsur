import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/events_tab_page.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/team/application/team_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Une étape des « Premiers pas ».
typedef FirstStep = ({String id, bool done});

/// Préférence : liste masquée pour une structure.
String firstStepsHiddenKey(String organizationId) =>
    'first_steps.hidden.$organizationId';

/// Étapes d'un nouveau promoteur, dans l'ordre, d'après ses données.
final Provider<List<FirstStep>>
firstStepsProvider = Provider.autoDispose<List<FirstStep>>((ref) {
  final organization = ref.watch(activeOrganizationProvider);
  final events = ref.watch(eventsProvider).value ?? const <TicketEvent>[];
  final live = events.where((e) => e.status != EventStatus.draft).firstOrNull;
  final issued = live == null
      ? 0
      : (ref.watch(categoriesProvider(live.id)).value ?? const []).fold(
          0,
          (sum, c) => sum + c.issued,
        );
  final team = ref.watch(teamProvider).value;
  final controller =
      (team?.members.any((m) => m.role == MemberRole.controller) ?? false) ||
      (team?.invitations.any((i) => i.role == MemberRole.controller) ?? false);
  return [
    (id: 'event', done: events.isNotEmpty),
    (id: 'publish', done: live != null),
    (id: 'issue', done: issued > 0),
    (id: 'team', done: controller),
    (id: 'phone', done: organization?.publicPhone != null),
  ];
});

/// Carte « Premiers pas » de l'accueil : progression et raccourcis, jusqu'à
/// ce que tout soit fait ou que le promoteur la masque.
class FirstStepsCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final organization = ref.watch(activeOrganizationProvider);
    final preferences = ref.watch(sharedPreferencesProvider);
    final hidden =
        organization == null ||
        !canManageEvents(organization) ||
        (preferences.getBool(firstStepsHiddenKey(organization.id)) ?? false);
    final steps = hidden ? const <FirstStep>[] : ref.watch(firstStepsProvider);
    final done = steps.where((s) => s.done).length;
    final visible =
        !hidden &&
        steps.isNotEmpty &&
        done < steps.length &&
        // Pas avant que les événements soient chargés : évite un éclair.
        ref.watch(eventsProvider).hasValue;
    final theme = Theme.of(context);
    String label(String id) => switch (id) {
      'event' => l10n.firstStepsEvent,
      'publish' => l10n.firstStepsPublish,
      'issue' => l10n.firstStepsIssue,
      'team' => l10n.firstStepsTeam,
      _ => l10n.firstStepsPhone,
    };
    void open(String id) => switch (id) {
      'event' => unawaited(context.push(AppRoutes.newEvent)),
      'publish' => context.go(AppRoutes.events),
      'issue' => context.go(AppRoutes.tickets),
      'team' => context.go(AppRoutes.team),
      _ => unawaited(context.push(AppRoutes.editOrganization)),
    };
    return MotionSize(
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: TicketSurSpacing.md),
              child: Card(
                key: const Key('first-steps'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TicketSurSpacing.md,
                    TicketSurSpacing.sm,
                    TicketSurSpacing.xs,
                    TicketSurSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.firstStepsTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            l10n.firstStepsProgress(done, steps.length),
                            key: const Key('first-steps-progress'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: context.palette.accentText,
                            ),
                          ),
                          TextButton(
                            key: const Key('first-steps-hide'),
                            onPressed: () => unawaited(
                              preferences
                                  .setBool(
                                    firstStepsHiddenKey(organization.id),
                                    true,
                                  )
                                  .then(
                                    (_) => ref.invalidate(firstStepsProvider),
                                  ),
                            ),
                            child: Text(l10n.firstStepsHide),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: TicketSurSpacing.sm,
                          bottom: TicketSurSpacing.xs,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: done / steps.length,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      for (final step in steps)
                        ListTile(
                          key: Key('first-step-${step.id}'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            step.done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: step.done
                                ? context.palette.successText
                                : theme.colorScheme.outline,
                          ),
                          title: Text(
                            label(step.id),
                            style: step.done
                                ? TextStyle(
                                    color: context.palette.mutedText,
                                    decoration: TextDecoration.lineThrough,
                                  )
                                : null,
                          ),
                          trailing: step.done
                              ? null
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: step.done ? null : () => open(step.id),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
