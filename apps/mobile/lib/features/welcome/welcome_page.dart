import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Accueil (S02) : identité de marque et entrée vers la connexion.
///
/// La connexion Supabase arrive avec le projet staging ; en attendant, le
/// bouton reste désactivé et la galerie des verdicts est accessible.
class WelcomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TicketSurSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Semantics(
                label: '${l10n.appName}, ${l10n.appSlogan}',
                image: true,
                child: Image.asset(
                  'assets/branding/TicketSur_Logo_Officiel.png',
                  height: 120,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('welcome-sign-in'),
                onPressed: null,
                child: Text(l10n.welcomeSignIn),
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              OutlinedButton(
                key: const Key('welcome-verdict-preview'),
                onPressed: () => context.push(AppRoutes.verdictPreview),
                child: Text(l10n.welcomeVerdictPreview),
              ),
              const SizedBox(height: TicketSurSpacing.md),
              Text(
                l10n.appSlogan,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
