import 'dart:typed_data';

import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';

/// Modèles de tickets en mémoire.
class FakeTicketTemplateRepository implements TicketTemplateRepository {
  new({
    Map<String, TicketTemplate>? templates,
    Map<String, TicketArtInfo>? info,
  }) : templates = templates ?? {},
       info = info ?? {};

  final Map<String, TicketTemplate> templates;
  final Map<String, TicketArtInfo> info;

  /// Appels : « save `catégorie` `builtin n|custom|default` », « upload ».
  final List<String> calls = [];

  /// Échec simulé du prochain enregistrement.
  TemplateFailure? nextFailure;

  @override
  Future<Map<String, TicketTemplate>> forEvent(String eventId) async =>
      Map.of(templates);

  @override
  Future<void> save(String categoryId, TicketTemplate? template) async {
    if (nextFailure case final failure?) {
      nextFailure = null;
      throw failure;
    }
    final kind = switch (template) {
      null => 'default',
      BuiltinTemplate(:final themeId, :final singleFontTitle) =>
        singleFontTitle ? 'builtin $themeId une-police' : 'builtin $themeId',
      CustomTemplate() => 'custom',
    };
    calls.add('save $categoryId $kind');
    if (template == null) {
      templates.remove(categoryId);
    } else {
      templates[categoryId] = template;
    }
  }

  @override
  Future<String> uploadImage(
    TicketEvent event,
    Uint8List bytes,
    String mimeType,
  ) async {
    calls.add('upload');
    return '${event.organizationId}/${event.id}/Modele_test.jpg';
  }

  @override
  String imageUrl(String path) => 'https://exemple.test/$path';

  @override
  Future<Map<String, TicketArtInfo>> artInfo(List<String> ticketIds) async => {
    for (final id in ticketIds) id: ?info[id],
  };
}
