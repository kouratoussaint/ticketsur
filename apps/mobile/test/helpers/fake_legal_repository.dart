import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/features/updates/domain/update_checker.dart';

/// Documents légaux en mémoire.
class FakeLegalRepository implements LegalRepository {
  new({this.failure});

  LegalFailure? failure;

  final Map<LegalSlug, LegalDocument> documents = {
    LegalSlug.terms: LegalDocument(
      slug: LegalSlug.terms,
      title: "Conditions d'utilisation",
      body:
          'Texte édité par [raison sociale].\n\n## 1. Le service\n'
          'Tikéo aide les promoteurs.\n- Un ticket, une entrée.',
      version: 1,
      updatedAt: DateTime.utc(2030, 5),
    ),
    LegalSlug.privacy: LegalDocument(
      slug: LegalSlug.privacy,
      title: 'Politique de confidentialité',
      body: 'Nous protégeons vos données.\n\n## Vos droits\n- Accès.',
      version: 2,
      updatedAt: DateTime.utc(2030, 5, 2),
    ),
  };

  final List<(LegalSlug, String, String)> saved = [];

  /// Versions anglaises (la française à défaut).
  final Map<LegalSlug, LegalDocument> english = {};

  /// Langue de chaque lecture et de chaque enregistrement.
  final List<String> fetchedLocales = [];
  final List<String> savedLocales = [];

  @override
  Future<LegalDocument> fetch(LegalSlug slug, {String locale = 'fr'}) async {
    if (failure case final f?) throw f;
    fetchedLocales.add(locale);
    return (locale == 'en' ? english[slug] : null) ?? documents[slug]!;
  }

  @override
  Future<int> save(
    LegalSlug slug, {
    required String title,
    required String body,
    String locale = 'fr',
  }) async {
    if (failure case final f?) throw f;
    savedLocales.add(locale);
    if (locale == 'en') {
      final version = (english[slug]?.version ?? 0) + 1;
      english[slug] = LegalDocument(
        slug: slug,
        title: title.trim(),
        body: body.trim(),
        version: version,
        updatedAt: DateTime.utc(2030, 6),
      );
      return version;
    }
    final current = documents[slug]!;
    saved.add((slug, title, body));
    documents[slug] = LegalDocument(
      slug: slug,
      title: title.trim(),
      body: body.trim(),
      version: current.version + 1,
      updatedAt: DateTime.utc(2030, 6),
    );
    return current.version + 1;
  }
}

/// Dernière version publiée, fixée par le test.
class FakeUpdateChecker implements UpdateChecker {
  new({this.latest});

  int? latest;
  int calls = 0;

  @override
  Future<int?> latestBuild() async {
    calls++;
    return latest;
  }
}
