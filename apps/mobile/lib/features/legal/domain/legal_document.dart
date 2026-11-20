import 'package:flutter/foundation.dart';

/// Documents légaux de Tikéo (migration 2500).
enum LegalSlug {
  terms('terms'),
  privacy('privacy');

  new(this.wireName);

  final String wireName;

  static LegalSlug? fromWire(String? value) =>
      values.where((s) => s.wireName == value).firstOrNull;
}

/// Un document légal, dans sa version en vigueur.
@immutable
final class LegalDocument {
  const new({
    required this.slug,
    required this.title,
    required this.body,
    required this.version,
    required this.updatedAt,
  });

  factory fromJson(Map<String, Object?> json) => LegalDocument(
    slug: LegalSlug.fromWire(json['slug'] as String?) ?? LegalSlug.terms,
    title: json['title']! as String,
    body: json['body']! as String,
    version: (json['version']! as num).toInt(),
    updatedAt: DateTime.parse(json['updated_at']! as String).toUtc(),
  );

  final LegalSlug slug;
  final String title;
  final String body;
  final int version;
  final DateTime updatedAt;
}

/// Échecs des documents légaux.
enum LegalFailure implements Exception { invalid, notFound, network, unknown }

/// Un document dans une langue (« fr », « en »).
typedef LegalKey = ({LegalSlug slug, String locale});

abstract interface class LegalRepository {
  /// Version en vigueur dans [locale] (la française à défaut).
  Future<LegalDocument> fetch(LegalSlug slug, {String locale = 'fr'});

  /// Console : enregistre une nouvelle version dans [locale] ; renvoie son
  /// numéro.
  Future<int> save(
    LegalSlug slug, {
    required String title,
    required String body,
    String locale = 'fr',
  });
}

/// Bloc du texte : intertitre (« ## »), puce (« - ») ou paragraphe.
sealed class LegalBlock {
  const new(this.text);

  final String text;
}

final class LegalHeading extends LegalBlock {
  const new(super.text);
}

final class LegalBullet extends LegalBlock {
  const new(super.text);
}

final class LegalParagraph extends LegalBlock {
  const new(super.text);
}

/// Découpe le corps d'un document en blocs.
List<LegalBlock> parseLegalBody(String body) {
  final blocks = <LegalBlock>[];
  final paragraph = <String>[];
  void flush() {
    if (paragraph.isNotEmpty) {
      blocks.add(LegalParagraph(paragraph.join(' ')));
      paragraph.clear();
    }
  }

  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) {
      flush();
    } else if (line.startsWith('## ')) {
      flush();
      blocks.add(LegalHeading(line.substring(3).trim()));
    } else if (line.startsWith('- ')) {
      flush();
      blocks.add(LegalBullet(line.substring(2).trim()));
    } else {
      paragraph.add(line);
    }
  }
  flush();
  return blocks;
}
