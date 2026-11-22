import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/events/presentation/event_status_chip.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/profile/presentation/user_avatar.dart';
import 'package:ticketsur/features/team/application/team_providers.dart';
import 'package:ticketsur/features/team/presentation/team_tab_page.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Fiche d'un membre de l'équipe (ADR 0048) : rôle, accès, entrées validées,
/// affectations aux événements à venir, et modification quand elle est
/// permise.
class MemberDetailPage extends ConsumerWidget {
  const new({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final member = ref
        .watch(teamProvider)
        .value
        ?.members
        .where((m) => m.userId == userId)
        .firstOrNull;
    final activity = ref.watch(memberActivityProvider(userId));
    final me = ref.watch(currentUserProvider).value?.id;
    final ownerView =
        ref.watch(activeOrganizationProvider)?.role == MemberRole.owner;
    final editable =
        member != null &&
        member.userId != me &&
        member.role != MemberRole.owner &&
        (ownerView || member.role == MemberRole.controller);
    final header = TikeoHeroHeader(
      title: l10n.memberDetailTitle,
      onBack: () => context.popOr(AppRoutes.team),
      overlap: member == null ? 0 : TikeoSizes.heroOverlap,
    );
    final day = DateFormat.yMMMd(appLocaleTag);
    final time = DateFormat.Hm(appLocaleTag);
    String when(DateTime at) =>
        '${day.format(at.toLocal())} · ${time.format(at.toLocal())}';

    final identity = member == null
        ? header
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              TikeoOverlapCard(
                child: Row(
                  children: [
                    UserAvatar(
                      initials: member.displayName.characters.first
                          .toUpperCase(),
                      radius: 30,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.userId == me
                                ? '${member.displayName} (${l10n.teamYou})'
                                : member.displayName,
                            key: const Key('member-detail-name'),
                            style: theme.textTheme.titleMedium,
                          ),
                          if (member.email case final email?)
                            Text(
                              email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.palette.mutedText,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              TikeoPill(
                                label: roleLabel(l10n, member.role),
                                tint: roleTint(member.role, tints),
                                icon: roleIcon(member.role),
                              ),
                              if (!member.active)
                                TikeoPill(
                                  label: l10n.teamInactive,
                                  tint: tints.gray,
                                  icon: Icons.pause_circle_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

    final body = switch (activity) {
      AsyncData(:final value) => [
        TikeoCard(
          key: const Key('member-detail-stats'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatStrip(
                centered: true,
                items: [
                  (
                    value: '${value.validated}',
                    label: l10n.memberValidated,
                    color: tints.mint.text,
                  ),
                  (
                    value: '${value.validated30d}',
                    label: l10n.memberValidated30d,
                    color: null,
                  ),
                  (
                    value: '${value.eventsWorked}',
                    label: l10n.memberEventsWorked,
                    color: null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                switch (value.lastValidatedAt) {
                  final at? => l10n.memberLastValidated(when(at)),
                  null => l10n.memberNeverValidated,
                },
                key: const Key('member-detail-last'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.palette.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TikeoSizes.sectionGap - 4),
        SectionHeader(
          title: l10n.memberAssignmentsTitle,
          icon: Icons.door_front_door_rounded,
        ),
        const SizedBox(height: 8),
        if (value.assignments.isEmpty)
          TikeoCard(
            key: const Key('member-detail-no-assignments'),
            child: Text(
              l10n.memberNoAssignments,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        for (final assignment in value.assignments)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TikeoListRow(
              key: Key('member-assignment-${assignment.eventId}'),
              title: assignment.eventTitle,
              subtitle: when(assignment.startsAt),
              lines: [assignment.checkpointName ?? l10n.memberAllDoors],
              badge: EventStatusChip(status: assignment.status),
              onTap: () => unawaited(
                context.push(AppRoutes.eventDetail(assignment.eventId)),
              ),
            ),
          ),
      ],
      AsyncError() => [
        TintedBanner(
          key: const Key('member-detail-error'),
          tint: tints.red,
          icon: Icons.wifi_off_rounded,
          title: l10n.memberActivityError,
        ),
      ],
      _ => [const Shimmer(child: SkeletonBox(height: 120, radius: 16))],
    };

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(memberActivityProvider(userId));
          try {
            await ref.read(memberActivityProvider(userId).future);
          } on Object {
            // L'échec s'affiche dans la page.
          }
        },
        child: ListView(
          key: const Key('member-detail'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: TikeoSizes.sectionGap),
          children: [
            identity,
            const SizedBox(height: TikeoSizes.cardGap),
            for (final child in [
              ...body,
              if (editable) ...[
                const SizedBox(height: TikeoSizes.cardGap),
                OutlinedButton.icon(
                  key: const Key('member-detail-edit'),
                  onPressed: () => unawaited(
                    showMemberSheet(
                      context,
                      member: member,
                      ownerView: ownerView,
                    ),
                  ),
                  icon: const Icon(Icons.manage_accounts_rounded),
                  label: Text(l10n.memberEdit),
                ),
              ],
            ])
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TikeoSizes.screenMargin,
                ),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}
