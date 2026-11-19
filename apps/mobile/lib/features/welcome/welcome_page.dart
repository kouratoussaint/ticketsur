import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// « Organiser » sans compte (refonte Tikéo) : ce que Tikéo apporte aux
/// organisateurs, et l'entrée vers la connexion. Le public, lui, reste sur
/// l'Explorer.
///
/// La galerie des verdicts reste accessible sans compte pour la revue UX.
class WelcomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    const white = TicketSurColors.white;
    Widget point(String text) => Padding(
      padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: TicketSurColors.mint,
            child: Icon(
              Icons.check_rounded,
              size: 18,
              color: TicketSurColors.navy,
            ),
          ),
          const SizedBox(width: TicketSurSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: textTheme.titleSmall?.copyWith(color: white),
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: TicketSurColors.navy,
      appBar: AppBar(
        backgroundColor: TicketSurColors.navy,
        foregroundColor: white,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: TicketSurSpacing.lg,
                ),
                children: [
                  FadeSlideIn(
                    duration: const Duration(milliseconds: 450),
                    child: Image.asset(
                      'assets/branding/Tikeo_Symbole.png',
                      height: 130,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: TicketSurSpacing.lg),
                  Text(
                    l10n.organizeTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(color: white),
                  ),
                  const SizedBox(height: TicketSurSpacing.sm),
                  Text(
                    l10n.organizeBody,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFC9D6E3),
                    ),
                  ),
                  const SizedBox(height: TicketSurSpacing.lg),
                  point(l10n.organizePoint1),
                  point(l10n.organizePoint2),
                  point(l10n.organizePoint3),
                ],
              ),
            ),
            Material(
              color: Theme.of(context).colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TicketSurSpacing.md,
                  TicketSurSpacing.lg,
                  TicketSurSpacing.md,
                  TicketSurSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      key: const Key('welcome-sign-in'),
                      onPressed: () => context.push(AppRoutes.signIn),
                      child: Text(l10n.welcomeSignIn),
                    ),
                    const SizedBox(height: TicketSurSpacing.xs),
                    TextButton(
                      key: const Key('welcome-verdict-preview'),
                      onPressed: () => context.push(AppRoutes.verdictPreview),
                      child: Text(l10n.welcomeVerdictPreview),
                    ),
                    Text(
                      l10n.appSlogan,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
