import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/double_back_to_exit.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Accueil (S02) : identité de marque et entrée vers la connexion.
///
/// Entrée animée (logo, puis actions), double appui sur Retour pour quitter.
/// La galerie des verdicts reste accessible sans compte pour la revue UX.
class WelcomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return DoubleBackToExit(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                FadeSlideIn(
                  duration: const Duration(milliseconds: 450),
                  child: Semantics(
                    label: '${l10n.appName}, ${l10n.appSlogan}',
                    image: true,
                    child: Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/branding/Tikeo_Logo_Clair.png'
                          : 'assets/branding/Tikeo_Logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                const Spacer(),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: FilledButton(
                    key: const Key('welcome-sign-in'),
                    onPressed: () => context.push(AppRoutes.signIn),
                    child: Text(l10n.welcomeSignIn),
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.sm),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 290),
                  child: OutlinedButton(
                    key: const Key('welcome-verdict-preview'),
                    onPressed: () => context.push(AppRoutes.verdictPreview),
                    child: Text(l10n.welcomeVerdictPreview),
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.md),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 360),
                  child: Text(
                    l10n.appSlogan,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
