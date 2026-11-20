import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/wallet/domain/wallet.dart';

/// « Mes tickets » ; surchargé dans `main.dart` et dans les tests.
final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => throw UnimplementedError(
    'walletRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Choisit une image dans la galerie et y lit un QR ; `null` si l'on
/// renonce ou si aucun QR n'est lisible. Remplacé dans les tests.
final qrFromImageProvider = Provider<Future<String?> Function()>(
  (ref) => () async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    final controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
    try {
      final capture = await controller.analyzeImage(picked.path);
      return capture?.barcodes
          .map((b) => b.rawValue)
          .whereType<String>()
          .firstOrNull;
    } finally {
      await controller.dispose();
    }
  },
);

/// Tickets du compte, avec leur source.
@immutable
final class WalletState {
  const new({required this.tickets, this.savedAt});

  final List<WalletTicket> tickets;

  /// Non nul : liste lue sur l'appareil (pas de réseau), enregistrée à cette
  /// heure. Les QR restent affichables ; le statut sera vérifié à l'entrée.
  final DateTime? savedAt;

  bool get offline => savedAt != null;
}

/// Clé du cache de l'appareil, par compte.
String walletCacheKey(String userId) => 'wallet.$userId';

/// « Mes tickets » : lus sur le serveur, gardés sur l'appareil pour être
/// présentés sans réseau.
class WalletController extends AsyncNotifier<WalletState> {
  @override
  Future<WalletState> build() async {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const WalletState(tickets: []);
    final preferences = ref.read(sharedPreferencesProvider);
    try {
      final tickets = await ref.read(walletRepositoryProvider).mine();
      await preferences.setString(
        walletCacheKey(user.id),
        jsonEncode({
          'saved_at': DateTime.now().toUtc().toIso8601String(),
          'tickets': [for (final t in tickets) t.toJson()],
        }),
      );
      return WalletState(tickets: tickets);
    } on WalletFailure catch (failure) {
      if (failure != WalletFailure.network) rethrow;
      final cached = _cached(user.id);
      if (cached == null) rethrow;
      return cached;
    }
  }

  WalletState? _cached(String userId) {
    final raw = ref
        .read(sharedPreferencesProvider)
        .getString(walletCacheKey(userId));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      return WalletState(
        savedAt: DateTime.parse(json['saved_at']! as String).toUtc(),
        tickets: [
          for (final row in json['tickets']! as List<Object?>)
            WalletTicket.fromJson(Map<String, Object?>.from(row! as Map)),
        ],
      );
    } on Object {
      return null;
    }
  }

  /// Ajoute un ticket par son QR ; renvoie son identifiant.
  /// Lève une [WalletFailure] en cas d'échec.
  Future<String> claim(String code) async {
    final token = code.trim();
    if (!walletTokenPattern.hasMatch(token)) throw WalletFailure.invalidCode;
    final id = await ref.read(walletRepositoryProvider).claim(token);
    ref.invalidateSelf();
    await future;
    return id;
  }

  Future<void> release(String ticketId) async {
    await ref.read(walletRepositoryProvider).release(ticketId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  /// Oublie les tickets gardés sur l'appareil (déconnexion).
  Future<void> forgetDevice(String userId) =>
      ref.read(sharedPreferencesProvider).remove(walletCacheKey(userId));
}

final AsyncNotifierProvider<WalletController, WalletState> walletProvider =
    AsyncNotifierProvider<WalletController, WalletState>(
      WalletController.new,
      retry: (retryCount, error) => null,
    );
