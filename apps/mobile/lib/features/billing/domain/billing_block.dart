import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';

/// Pourquoi le pack bloque une action.
enum BillingBlockKind {
  /// Limite chiffrée atteinte (`billing_limit_<option>`).
  limit,

  /// Fonction non comprise (`billing_option_<option>`).
  option,

  /// Facture à l'usage en retard (`billing_overdue`).
  overdue,

  /// Événement à l'usage sans pack choisi (`billing_usage_pack_missing`).
  usagePackMissing,
}

/// Action refusée par le pack (P8 · Limite atteinte). Le serveur met dans
/// HINT un JSON : limite, système et, à l'usage, l'événement concerné.
@immutable
final class BillingBlock {
  const new({
    required this.kind,
    this.option,
    this.limit,
    this.system = BillingSystem.flat,
    this.eventId,
  });

  /// Lit une erreur du serveur ; null si ce n'est pas un blocage du pack.
  static BillingBlock? fromError(Object error) {
    if (error is! supabase.PostgrestException) return null;
    final message = error.message;
    final BillingBlockKind kind;
    BillingOption? option;
    if (message.startsWith('billing_limit_')) {
      kind = BillingBlockKind.limit;
      option = BillingOption.byKey(message.substring(14));
    } else if (message.startsWith('billing_option_')) {
      kind = BillingBlockKind.option;
      option = BillingOption.byKey(message.substring(15));
    } else if (message == 'billing_overdue') {
      kind = BillingBlockKind.overdue;
    } else if (message == 'billing_usage_pack_missing') {
      kind = BillingBlockKind.usagePackMissing;
    } else {
      return null;
    }
    var hint = const <String, Object?>{};
    try {
      final decoded = jsonDecode(error.hint ?? '');
      if (decoded is Map) hint = decoded.cast<String, Object?>();
      // HINT d'une ancienne version : le nombre seul.
      if (decoded is num) hint = {'limit': decoded};
    } on FormatException {
      // HINT d'une ancienne version : le nombre seul.
      hint = {'limit': int.tryParse(error.hint ?? '')};
    }
    return BillingBlock(
      kind: kind,
      option: option,
      limit: (hint['limit'] as num?)?.toInt(),
      system: BillingSystem.fromWire(hint['system']),
      eventId: hint['event'] as String?,
    );
  }

  final BillingBlockKind kind;
  final BillingOption? option;

  /// Valeur permise (suppléments compris).
  final int? limit;
  final BillingSystem system;

  /// Événement à l'usage concerné (« Dépasser la limite »).
  final String? eventId;
}

/// Derniers blocages du pack, affichés par la feuille « Limite atteinte ».
/// Rempli par les dépôts quand le serveur refuse une action.
final ValueNotifier<BillingBlock?> billingBlocks = ValueNotifier(null);

/// Heure du dernier blocage : les messages d'erreur génériques qui le
/// suivent sont tus (la feuille l'explique).
DateTime? lastBillingBlockAt;

/// Retient [error] s'il vient du pack ; vrai dans ce cas.
bool captureBillingBlock(Object error) {
  final block = BillingBlock.fromError(error);
  if (block == null) return false;
  reportBillingBlock(block);
  return true;
}

/// Signale un blocage connu de l'app (fonction non comprise).
void reportBillingBlock(BillingBlock block) {
  lastBillingBlockAt = DateTime.now();
  // Nouvelle instance à chaque fois : les auditeurs sont prévenus même si le
  // même blocage se répète.
  billingBlocks.value = BillingBlock(
    kind: block.kind,
    option: block.option,
    limit: block.limit,
    system: block.system,
    eventId: block.eventId,
  );
}

/// Un blocage vient d'être signalé (moins de 3 secondes).
bool get billingBlockJustReported =>
    lastBillingBlockAt != null &&
    DateTime.now().difference(lastBillingBlockAt!) < const Duration(seconds: 3);
