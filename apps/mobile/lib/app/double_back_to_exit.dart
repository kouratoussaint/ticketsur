import 'dart:async';

import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Action « quitter l'application » (remplacée dans les tests).
final appExitProvider = Provider<Future<void> Function()>(
  (ref) => SystemNavigator.pop,
);

/// Double appui sur Retour pour quitter, sur les écrans racines.
///
/// Ordre de traitement d'un appui sur Retour :
/// 1. fermer la page empilée s'il y en a une ;
/// 2. sinon, [onBackIntercept] (par exemple revenir à l'onglet précédent) ;
/// 3. sinon, premier appui : message « Appuyez encore… » ; second appui dans
///    les [window] suivantes : sortie de l'application.
class DoubleBackToExit extends ConsumerStatefulWidget {
  const new({
    required this.child,
    this.onBackIntercept,
    this.window = const Duration(seconds: 2),
    this.clock = DateTime.now,
    super.key,
  });

  final Widget child;

  /// Retourne `true` s'il a consommé l'appui sur Retour.
  final bool Function()? onBackIntercept;

  /// Délai pendant lequel le second appui fait quitter.
  final Duration window;

  /// Horloge (remplacée dans les tests).
  final DateTime Function() clock;

  @override
  ConsumerState<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends ConsumerState<DoubleBackToExit> {
  DateTime? _firstPress;

  void _onBack() {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
      return;
    }
    if (widget.onBackIntercept?.call() ?? false) return;
    final now = widget.clock();
    final first = _firstPress;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (first != null && now.difference(first) <= widget.window) {
      messenger?.hideCurrentSnackBar();
      unawaited(ref.read(appExitProvider)());
      return;
    }
    _firstPress = now;
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('exit-confirm'),
          content: Text(context.l10n.exitConfirm),
          duration: widget.window,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: widget.child,
    );
  }
}
