import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Application de repli quand la configuration Supabase est absente ou
/// refusée (clé secrète, URL non HTTPS) : rien n'est contacté.
class ConfigurationErrorApp extends StatelessWidget {
  const new({required this.problem, super.key});

  /// Problème détecté par `AppConfig.problem`.
  final String problem;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TicketSurTheme.light(),
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final textTheme = Theme.of(context).textTheme;
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(TicketSurSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.settings_suggest_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: TicketSurSpacing.lg),
                    Text(
                      l10n.configErrorTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: TicketSurSpacing.sm),
                    Text(
                      problem,
                      key: const Key('config-problem'),
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: TicketSurSpacing.md),
                    Text(
                      l10n.configErrorHint,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
