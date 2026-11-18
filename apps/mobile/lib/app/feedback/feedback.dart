import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketsur/design_system/verdict_colors.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';

/// Sons de l'application (créations originales, voir
/// tools/sounds/generate_sounds.py).
enum UiSound {
  /// Clic doux de navigation.
  tap(0.45),

  /// Action réussie.
  success(0.8),

  /// Action refusée ou échouée.
  error(0.8),

  /// Contrôle : entrée autorisée.
  admitted(1),

  /// Contrôle : entrée refusée.
  refused(1),

  /// Contrôle : état à confirmer.
  indeterminate(0.9);

  new(this.volume);

  /// Volume relatif (0 à 1).
  final double volume;

  /// Chemin de l'asset, relatif à `assets/`.
  String get asset => 'sounds/$name.wav';
}

/// Lecteur de sons (remplacé en test).
abstract interface class SoundPlayer {
  Future<void> play(UiSound sound);
}

/// Lecteur basse latence : un petit groupe de lecteurs par son, créé à la
/// première utilisation. Les sons n'interrompent pas la musique du
/// téléphone (pas de prise de focus audio).
class AudioPoolSoundPlayer implements SoundPlayer {
  final Map<UiSound, Future<AudioPool>> _pools = {};
  bool _configured = false;

  Future<AudioPool> _pool(UiSound sound) => _pools[sound] ??= () async {
    if (!_configured) {
      _configured = true;
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
    }
    return await AudioPool.createFromAsset(
      path: sound.asset,
      maxPlayers: 3,
      playerMode: PlayerMode.lowLatency,
    );
  }();

  @override
  Future<void> play(UiSound sound) async {
    try {
      await (await _pool(sound)).start(volume: sound.volume);
    } on Object {
      // Un son manqué ne doit jamais bloquer l'interface ni le contrôle.
      _pools.remove(sound)?.ignore();
    }
  }
}

/// Lecteur de sons de l'application.
final soundPlayerProvider = Provider<SoundPlayer>(
  (ref) => AudioPoolSoundPlayer(),
);

/// Réglages des retours sonores et haptiques (S28), propres à l'appareil.
@immutable
final class FeedbackSettings {
  const new({
    this.scanSounds = true,
    this.uiSounds = true,
    this.haptics = true,
  });

  /// Sons des verdicts de contrôle.
  final bool scanSounds;

  /// Sons de l'interface (navigation, confirmations).
  final bool uiSounds;

  /// Vibrations.
  final bool haptics;

  FeedbackSettings copyWith({
    bool? scanSounds,
    bool? uiSounds,
    bool? haptics,
  }) => FeedbackSettings(
    scanSounds: scanSounds ?? this.scanSounds,
    uiSounds: uiSounds ?? this.uiSounds,
    haptics: haptics ?? this.haptics,
  );
}

/// Réglages persistés dans les préférences de l'appareil.
class FeedbackSettingsController extends Notifier<FeedbackSettings> {
  static const _scan = 'feedback.scan_sounds';
  static const _ui = 'feedback.ui_sounds';
  static const _haptics = 'feedback.haptics';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  FeedbackSettings build() => FeedbackSettings(
    scanSounds: _prefs.getBool(_scan) ?? true,
    uiSounds: _prefs.getBool(_ui) ?? true,
    haptics: _prefs.getBool(_haptics) ?? true,
  );

  Future<void> update(FeedbackSettings next) async {
    state = next;
    await _prefs.setBool(_scan, next.scanSounds);
    await _prefs.setBool(_ui, next.uiSounds);
    await _prefs.setBool(_haptics, next.haptics);
  }
}

final NotifierProvider<FeedbackSettingsController, FeedbackSettings>
feedbackSettingsProvider =
    NotifierProvider<FeedbackSettingsController, FeedbackSettings>(
      FeedbackSettingsController.new,
    );

/// Retours sonores et haptiques, selon les réglages.
class AppFeedback {
  new(this._ref);

  final Ref _ref;

  FeedbackSettings get _settings => _ref.read(feedbackSettingsProvider);

  void _sound(UiSound sound, {required bool enabled}) {
    if (enabled) unawaited(_ref.read(soundPlayerProvider).play(sound));
  }

  void _haptic(Future<void> Function() effect) {
    if (_settings.haptics) unawaited(effect());
  }

  /// Navigation, choix dans une liste.
  void tap() {
    _haptic(HapticFeedback.selectionClick);
    _sound(UiSound.tap, enabled: _settings.uiSounds);
  }

  /// Action réussie (création, enregistrement, partage…).
  void success() {
    _haptic(HapticFeedback.lightImpact);
    _sound(UiSound.success, enabled: _settings.uiSounds);
  }

  /// Action refusée ou échouée.
  void error() {
    _haptic(HapticFeedback.mediumImpact);
    _sound(UiSound.error, enabled: _settings.uiSounds);
  }

  /// Verdict de contrôle : son distinct pour chaque issue.
  void verdict(VerdictKind kind) {
    final enabled = _settings.scanSounds;
    switch (kind) {
      case VerdictKind.admitted:
        _haptic(HapticFeedback.mediumImpact);
        _sound(UiSound.admitted, enabled: enabled);
      case VerdictKind.refused:
        _haptic(HapticFeedback.heavyImpact);
        _sound(UiSound.refused, enabled: enabled);
      case VerdictKind.indeterminate:
        _haptic(HapticFeedback.heavyImpact);
        _sound(UiSound.indeterminate, enabled: enabled);
      case VerdictKind.verifying:
        break;
    }
  }

  /// Écoute d'un son depuis les réglages (ignore les interrupteurs).
  void preview(UiSound sound) =>
      unawaited(_ref.read(soundPlayerProvider).play(sound));
}

/// Retours de l'application.
final feedbackProvider = Provider<AppFeedback>(AppFeedback.new);
