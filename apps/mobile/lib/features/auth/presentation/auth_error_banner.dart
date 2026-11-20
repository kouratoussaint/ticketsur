import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/features/auth/domain/auth_repository.dart';

/// Bandeau d'erreur annoncé à TalkBack dès son apparition (écran C de la
/// direction artistique) : rouge pour un refus, ambre pour une attente
/// (adresse non confirmée, trop de tentatives), bleu sans connexion.
class AuthErrorBanner extends StatelessWidget {
  const new({required this.message, this.failure, super.key});

  final String message;

  /// Cause, pour la couleur ; rouge par défaut.
  final AuthFailure? failure;

  @override
  Widget build(BuildContext context) {
    final tints = context.tints;
    final (tint, icon) = switch (failure) {
      AuthFailure.emailNotConfirmed => (
        tints.amber,
        Icons.mark_email_unread_rounded,
      ),
      AuthFailure.rateLimited => (tints.amber, Icons.hourglass_top_rounded),
      AuthFailure.network => (tints.blue, Icons.wifi_off_rounded),
      _ => (tints.red, Icons.error_rounded),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const Key('auth-error'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tint.background,
          borderRadius: BorderRadius.circular(TikeoRadii.field),
        ),
        child: Row(
          children: [
            Icon(icon, color: tint.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: tint.text, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
