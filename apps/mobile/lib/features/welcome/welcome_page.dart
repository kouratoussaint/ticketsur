import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';
import 'package:ticketsur/features/announcements/presentation/announcement_banner.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Présentation de l'espace promoteur sans compte : créer un compte, se
/// connecter ou rejoindre une équipe avec un code. (Les événements se
/// découvrent dans Explorer.)
class WelcomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final mint = context.tints.mint;
    final canPop = Navigator.of(context).canPop();
    Widget point(String text) => Padding(
      padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: mint.background,
            child: Icon(Icons.check_rounded, size: 18, color: mint.icon),
          ),
          const SizedBox(width: TicketSurSpacing.sm),
          Expanded(child: Text(text, style: textTheme.titleSmall)),
        ],
      ),
    );
    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: TikeoSizes.screenMargin),
      child: child,
    );
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: TicketSurSpacing.lg),
              children: [
                TikeoHeroHeader(
                  key: const Key('welcome-header'),
                  title: l10n.welcomeOrganizeTitle,
                  subtitle: l10n.appSlogan,
                  illustration: TikeoIllustration.calendar,
                  onBack: canPop
                      ? () => Navigator.of(context).maybePop()
                      : null,
                  actions: [
                    if (canPop)
                      const TikeoLogo(
                        height: TikeoSizes.headerLogo,
                        onDark: true,
                      ),
                  ],
                  overlap: 0,
                ),
                const SizedBox(height: TikeoSizes.cardGap),
                const AnnouncementBanner(
                  padding: EdgeInsets.fromLTRB(
                    TikeoSizes.screenMargin,
                    0,
                    TikeoSizes.screenMargin,
                    TikeoSizes.cardGap,
                  ),
                ),
                // Organiser -------------------------------------------------
                padded(
                  TikeoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: l10n.organizeTitle,
                          icon: Icons.campaign_rounded,
                        ),
                        const SizedBox(height: TicketSurSpacing.xs),
                        Text(l10n.organizeBody, style: textTheme.bodyMedium),
                        const SizedBox(height: TicketSurSpacing.md),
                        point(l10n.organizePoint1),
                        point(l10n.organizePoint2),
                        point(l10n.organizePoint3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // « Votre espace Tikéo » : créer un compte, se connecter, code.
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(TikeoRadii.navBar),
              ),
              boxShadow: TikeoShadows.cardFor(theme.brightness),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TicketSurSpacing.md,
                  TicketSurSpacing.md,
                  TicketSurSpacing.md,
                  TicketSurSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.welcomeSpaceTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: TicketSurSpacing.sm),
                    TikeoPrimaryButton(
                      key: const Key('welcome-sign-up'),
                      onPressed: () =>
                          unawaited(context.push(AppRoutes.signUp)),
                      icon: Icons.person_add_alt_1_rounded,
                      label: l10n.welcomeCreateAccount,
                    ),
                    const SizedBox(height: TicketSurSpacing.xs),
                    OutlinedButton(
                      key: const Key('welcome-sign-in'),
                      onPressed: () =>
                          unawaited(context.push(AppRoutes.signIn)),
                      child: Text(l10n.welcomeSignIn),
                    ),
                    TextButton.icon(
                      key: const Key('welcome-code'),
                      onPressed: () =>
                          unawaited(context.push(AppRoutes.signUpWithCode)),
                      icon: const Icon(Icons.key_rounded),
                      label: Text(l10n.welcomeHaveCode),
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton(
                          key: const Key('welcome-terms'),
                          onPressed: () => unawaited(
                            context.push(AppRoutes.legal(LegalSlug.terms)),
                          ),
                          child: Text(
                            l10n.legalTerms,
                            style: textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          key: const Key('welcome-privacy'),
                          onPressed: () => unawaited(
                            context.push(AppRoutes.legal(LegalSlug.privacy)),
                          ),
                          child: Text(
                            l10n.legalPrivacy,
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
