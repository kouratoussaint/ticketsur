import 'package:flutter/foundation.dart';

/// Catégorie d'une demande de support.
enum SupportCategory {
  question('question'),
  problem('problem'),
  account('account'),
  payment('payment'),
  other('other');

  new(this.wireName);

  final String wireName;

  static SupportCategory fromWire(Object? value) =>
      values.firstWhere((c) => c.wireName == value, orElse: () => other);
}

/// État d'une demande.
enum SupportStatus {
  /// En attente d'une réponse de l'équipe.
  open('open'),

  /// L'équipe a répondu.
  answered('answered'),

  /// Fermée.
  closed('closed');

  new(this.wireName);

  final String wireName;

  static SupportStatus fromWire(Object? value) =>
      values.firstWhere((s) => s.wireName == value, orElse: () => open);
}

DateTime _date(Object? value) => DateTime.parse(value! as String).toUtc();

/// Une demande de support (vue de l'utilisateur ou de la console).
@immutable
final class SupportRequest {
  const new({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.unread,
    required this.createdAt,
    required this.lastMessageAt,
    this.requesterName,
    this.requesterEmail,
    this.organizationName,
    this.messages = 0,
  });

  factory fromJson(Map<String, Object?> json) => SupportRequest(
    id: json['id']! as String,
    subject: json['subject']! as String,
    category: SupportCategory.fromWire(json['category']),
    status: SupportStatus.fromWire(json['status']),
    unread: json['unread'] == true,
    createdAt: _date(json['created_at']),
    lastMessageAt: _date(json['last_message_at']),
    requesterName: json['requester_name'] as String?,
    requesterEmail: json['requester_email'] as String?,
    organizationName: json['organization_name'] as String?,
    messages: (json['messages'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String subject;
  final SupportCategory category;
  final SupportStatus status;

  /// Nouvelle réponse pour le lecteur (utilisateur ou console).
  final bool unread;
  final DateTime createdAt;
  final DateTime lastMessageAt;

  // Console seulement.
  final String? requesterName;
  final String? requesterEmail;
  final String? organizationName;
  final int messages;
}

/// Un message du fil d'une demande.
@immutable
final class SupportMessage {
  const new({
    required this.id,
    required this.fromAdmin,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  factory fromJson(Map<String, Object?> json) => SupportMessage(
    id: json['id']! as String,
    fromAdmin: json['from_admin'] == true,
    authorName: json['author_name']! as String,
    body: json['body']! as String,
    createdAt: _date(json['created_at']),
  );

  final String id;
  final bool fromAdmin;
  final String authorName;
  final String body;
  final DateTime createdAt;
}

/// Compteurs du support pour la console.
typedef SupportCounts = ({int open, int unread, int answered});

/// Échecs du support.
enum SupportFailure implements Exception {
  /// Sujet ou message hors limites.
  invalid,

  /// 5 demandes en cours, ou trop de messages en une heure.
  limit,

  /// Demande introuvable ou d'un autre compte.
  notFound,

  /// Pas de réseau.
  network,

  /// Autre erreur.
  unknown,
}

/// Support par formulaire (migration 2300).
abstract interface class SupportRepository {
  Future<List<SupportRequest>> myRequests();

  /// Ouvre une demande ; renvoie son identifiant.
  Future<String> create({
    required String subject,
    required SupportCategory category,
    required String body,
    String? organizationId,
  });

  /// Fil de la demande (la marque lue pour le lecteur).
  Future<List<SupportMessage>> thread(String requestId);

  /// Ajoute un message ; renvoie le nouvel état.
  Future<SupportStatus> reply(String requestId, String body);

  Future<void> close(String requestId);

  /// Console : demandes, non lues d'abord.
  Future<List<SupportRequest>> adminRequests({
    SupportStatus? status,
    String search = '',
    int offset = 0,
    int limit = 30,
  });

  /// Console : compteurs.
  Future<SupportCounts> adminCounts();
}
