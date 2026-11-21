import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/security/application/security_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Verrouille l'app (lot 4-6a) quand le verrouillage par empreinte est
/// activé : au lancement avec une session ouverte, puis au retour après
/// [appLockDelayProvider] hors de l'app. L'écran de déverrouillage passe
/// par-dessus [child], qui garde son état.
class AppLockGate extends ConsumerStatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _lifecycle;
  late final ProviderSubscription<AsyncValue<Object?>> _user;
  DateTime? _hiddenAt;
  bool _launchChecked = false;

  bool get _signedIn => ref.read(currentUserProvider).value != null;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _hiddenAt ??= DateTime.now(),
      onShow: _onShow,
    );
    _user = ref.listenManual(
      currentUserProvider,
      (_, next) => _onUser(next),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _user.close();
    _lifecycle.dispose();
    super.dispose();
  }

  void _onUser(AsyncValue<Object?> next) {
    if (next.isLoading) return;
    final signedIn = next.value != null;
    final lockAtLaunch =
        !_launchChecked && signedIn && ref.read(appLockSettingProvider);
    _launchChecked = true;
    if (!lockAtLaunch && signedIn) return;
    // Hors de la construction des widgets.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locked = ref.read(appLockedProvider.notifier);
      // Lancement avec une session ouverte : verrouillé. Déconnecté : plus
      // rien à protéger.
      lockAtLaunch ? locked.lock() : locked.unlock();
    });
  }

  void _onShow() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    // Pendant la demande d'empreinte (code du téléphone : autre écran), on
    // ne reverrouille pas.
    if (hiddenAt == null || _authenticating) return;
    if (!ref.read(appLockSettingProvider) || !_signedIn) return;
    if (DateTime.now().difference(hiddenAt) >= ref.read(appLockDelayProvider)) {
      ref.read(appLockedProvider.notifier).lock();
    }
  }

  bool get _authenticating => ref.read(_authenticatingProvider);

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(appLockedProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: locked,
          child: IgnorePointer(ignoring: locked, child: widget.child),
        ),
        if (locked) const Positioned.fill(child: AppLockScreen()),
      ],
    );
  }
}

/// Demande d'empreinte en cours.
class _Authenticating extends Notifier<bool> {
  @override
  bool build() => false;

  // Nom imposé par Riverpod pour modifier l'état depuis l'extérieur.
  // ignore: use_setters_to_change_properties
  void set(bool value) => state = value;
}

final _authenticatingProvider = NotifierProvider<_Authenticating, bool>(
  _Authenticating.new,
);

/// Demande l'empreinte (ou le code du téléphone) ; vrai si réussi.
Future<bool> askBiometric(WidgetRef ref, String reason) async {
  final flag = ref.read(_authenticatingProvider.notifier)..set(true);
  try {
    return await ref.read(biometricServiceProvider).authenticate(reason);
  } finally {
    flag.set(false);
  }
}

/// Écran « Tikéo est verrouillé » : déverrouiller, ou se déconnecter.
class AppLockScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Demande tout de suite, comme les applications bancaires.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_unlock()));
  }

  Future<void> _unlock() async {
    if (!mounted || ref.read(_authenticatingProvider)) return;
    final ok = await askBiometric(ref, context.l10n.appLockReason);
    if (!mounted) return;
    if (ok) {
      ref.read(appLockedProvider.notifier).unlock();
    } else {
      setState(() => _failed = true);
    }
  }

  Future<void> _signOut() async {
    try {
      await signOutToExplore(
        ref.read(routerProvider),
        ref.read(authRepositoryProvider).signOut,
      );
    } on Object {
      // La session locale est fermée quoi qu'il arrive.
    }
    ref.read(appLockedProvider.notifier).unlock();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    const white = TicketSurColors.white;
    return Material(
      key: const Key('app-lock'),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: TikeoColors.heroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TikeoSizes.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Center(child: TikeoLogo(height: 56, onDark: true)),
                const SizedBox(height: TikeoSizes.sectionGap),
                const Icon(Icons.lock_rounded, color: white, size: 48),
                const SizedBox(height: 12),
                Text(
                  l10n.appLockTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(color: white),
                ),
                const SizedBox(height: 8),
                Text(
                  _failed ? l10n.appLockFailed : l10n.appLockBody,
                  key: const Key('app-lock-message'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: white.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(),
                TikeoPrimaryButton(
                  key: const Key('app-lock-unlock'),
                  label: l10n.appLockUnlock,
                  icon: Icons.fingerprint_rounded,
                  onPressed: () => unawaited(_unlock()),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('app-lock-sign-out'),
                  style: TextButton.styleFrom(
                    foregroundColor: TikeoColors.mintBright,
                  ),
                  onPressed: () => unawaited(_signOut()),
                  child: Text(l10n.appLockSignOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
