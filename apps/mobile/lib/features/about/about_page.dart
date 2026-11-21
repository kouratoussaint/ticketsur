import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/features/legal/presentation/legal_pages.dart';
import 'package:ticketsur/features/updates/application/update_providers.dart';
import 'package:ticketsur/features/updates/presentation/update_banner.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// À propos (#8) : version, mise à jour, mentions légales, contact.
/// Sortie des Paramètres, ouverte depuis le Profil.
class AboutPage extends ConsumerWidget {
  const new({super.key});

  Future<void> _check(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    try {
      await ref.read(availableUpdateProvider.notifier).checkNow();
    } on Object {
      toast.info(l10n.settingsCheckFailed);
      return;
    }
    final state = ref.read(availableUpdateProvider);
    if (state.value == null) {
      final failed = ref.read(installedBuildProvider) > 0 && state.hasError;
      toast.info(failed ? l10n.settingsCheckFailed : l10n.settingsUpToDate);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final installed = ref.watch(installedBuildProvider);
    final update = ref.watch(availableUpdateProvider);
    final lastCheck = ref.watch(lastUpdateCheckProvider);
    final signedIn = ref.watch(currentUserProvider).value != null;
    final checking = update.isLoading;
    return Scaffold(
      body: ListView(
        key: const Key('about'),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
        ),
        children: [
          TikeoHeroHeader(
            title: l10n.aboutTitle,
            subtitle: l10n.appSlogan,
            onBack: () => context.popOr(AppRoutes.profile),
            overlap: 0,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TikeoSizes.screenMargin,
              TikeoSizes.cardGap,
              TikeoSizes.screenMargin,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TikeoCard(
                  child: Row(
                    children: [
                      const TikeoLogo(height: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.appSlogan,
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              installed > 0
                                  ? l10n.settingsVersion(installed)
                                  : l10n.settingsVersionDev,
                              key: const Key('about-version'),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TikeoSizes.cardGap),
                const UpdateBanner(),
                TikeoCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      if (update.value == null && installed > 0)
                        SettingsRow(
                          key: const Key('about-up-to-date'),
                          icon: Icons.verified_rounded,
                          tint: tints.green,
                          title: l10n.settingsUpToDate,
                          subtitle: lastCheck == null
                              ? null
                              : l10n.aboutLastCheck(
                                  DateFormat.yMMMd(appLocaleTag)
                                      .add_Hm()
                                      .format(lastCheck),
                                ),
                          trailing: const SizedBox.shrink(),
                        ),
                      SettingsRow(
                        key: const Key('about-check-update'),
                        icon: Icons.system_update_rounded,
                        tint: tints.blue,
                        title: l10n.aboutCheckNow,
                        trailing: checking
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        onTap: installed > 0 && !checking
                            ? () => unawaited(_check(context, ref))
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TikeoSizes.sectionGap),
                SectionHeader(
                  title: l10n.aboutLegal,
                  icon: Icons.gavel_rounded,
                ),
                const SizedBox(height: 8),
                TikeoCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final slug in LegalSlug.values)
                        SettingsRow(
                          key: Key('about-legal-${slug.wireName}'),
                          icon: slug == LegalSlug.terms
                              ? Icons.gavel_rounded
                              : Icons.privacy_tip_rounded,
                          tint: tints.gray,
                          title: legalTitle(l10n, slug),
                          onTap: () =>
                              unawaited(context.push(AppRoutes.legal(slug))),
                        ),
                    ],
                  ),
                ),
                if (signedIn) ...[
                  const SizedBox(height: TikeoSizes.sectionGap),
                  SectionHeader(
                    title: l10n.aboutContact,
                    icon: Icons.support_agent_rounded,
                  ),
                  const SizedBox(height: 8),
                  TikeoCard(
                    padding: const EdgeInsets.all(4),
                    child: SettingsRow(
                      key: const Key('about-support'),
                      icon: Icons.support_agent_rounded,
                      tint: tints.violet,
                      title: l10n.profileSupport,
                      onTap: () => unawaited(context.push(AppRoutes.support)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
