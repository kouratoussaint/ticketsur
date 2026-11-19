import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Logo horizontal Tikéo, dans la variante lisible sur le fond du thème
/// (texte bleu nuit en clair, blanc en sombre), ou blanc si [onDark].
class TikeoLogo extends StatelessWidget {
  const new({this.height = 48, this.onDark, super.key});

  final double height;

  /// Force la variante pour fond sombre (bandeaux bleu nuit) ; par défaut,
  /// selon le thème.
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final dark = onDark ?? Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: context.l10n.appName,
      image: true,
      child: ExcludeSemantics(
        child: Image.asset(
          dark
              ? 'assets/branding/Tikeo_Logo_Clair.png'
              : 'assets/branding/Tikeo_Logo.png',
          key: const Key('tikeo-logo'),
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
