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

  @override
  Future<LegalDocument> fetch(LegalSlug slug) async {
    if (failure case final f?) throw f;
    return documents[slug]!;
  }

  @override
  Future<int> save(
    LegalSlug slug, {
    required String title,
    required String body,
  }) async {
    if (failure case final f?) throw f;
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
