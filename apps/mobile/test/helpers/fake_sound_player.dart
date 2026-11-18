import 'package:ticketsur/app/feedback/feedback.dart';

/// Lecteur de sons de test : enregistre au lieu de jouer.
class FakeSoundPlayer implements SoundPlayer {
  final List<UiSound> played = [];

  @override
  Future<void> play(UiSound sound) async => played.add(sound);
}
