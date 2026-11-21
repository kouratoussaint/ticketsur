import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/admin_accounts/application/admin_accounts_providers.dart';
import 'package:ticketsur/features/auth/presentation/new_password_page.dart';

/// Compte créé ou mot de passe donné par la console : le nouveau mot de
/// passe est choisi avant tout le reste (lot 4-11a).
class PasswordChangeGate extends ConsumerWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forced = ref.watch(mustChangePasswordProvider).value ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: forced,
          child: IgnorePointer(ignoring: forced, child: child),
        ),
        if (forced)
          Positioned.fill(
            // Navigateur propre : champs de saisie (sélection) et feuilles.
            child: Navigator(
              key: const Key('password-change-gate'),
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (context) => NewPasswordPage(
                  onChanged: () async {
                    await ref
                        .read(adminAccountsRepositoryProvider)
                        .clearMustChangePassword();
                    ref.invalidate(mustChangePasswordProvider);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
