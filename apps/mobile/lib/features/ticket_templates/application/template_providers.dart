import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ticketsur/features/events/application/cover_picker.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';

/// Dépôt des modèles ; surchargé dans `main.dart` et les tests.
final ticketTemplateRepositoryProvider = Provider<TicketTemplateRepository>(
  (ref) => throw UnimplementedError(
    'ticketTemplateRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Modèles enregistrés des catégories d'un événement.
final FutureProviderFamily<Map<String, TicketTemplate>, String>
eventTemplatesProvider = FutureProvider.autoDispose
    .family<Map<String, TicketTemplate>, String>(
      (ref, eventId) =>
          ref.watch(ticketTemplateRepositoryProvider).forEvent(eventId),
    );

/// Prépare le dessin des tickets [ticketIds] de [event] : structure active,
/// modèles et numéros. Un échec de lecture n'empêche jamais l'envoi : le
/// modèle proposé est utilisé, sans numéro.
Future<TicketArt> loadTicketArt(
  WidgetRef ref,
  TicketEvent event,
  List<String> ticketIds,
) async {
  final repository = ref.read(ticketTemplateRepositoryProvider);
  final organization = ref.read(activeOrganizationProvider);
  Map<String, TicketTemplate> templates;
  try {
    templates = await repository.forEvent(event.id);
  } on Object {
    templates = const {};
  }
  Map<String, TicketArtInfo> info;
  try {
    info = ticketIds.isEmpty ? const {} : await repository.artInfo(ticketIds);
  } on Object {
    info = const {};
  }
  return TicketArt(
    event: event,
    organizationName: organization?.name ?? '',
    organizationLogoUrl: organization?.logoUrl,
    templates: templates,
    info: info,
  );
}

/// Image d'un design choisie sur le téléphone.
typedef TemplateImage = ({Uint8List bytes, String mimeType});

/// Choix d'une image de design (galerie ; faux sélecteur en test).
final templateImagePickerProvider = Provider<Future<TemplateImage?> Function()>(
  (ref) => () async {
    // 2400 px au plus : net à l'impression, sous la limite de 2 Mo.
    final image = await pickImage(CoverSource.gallery, maxDimension: 2400);
    return image == null
        ? null
        : (bytes: image.bytes, mimeType: image.mimeType);
  },
);

/// Taille d'une image et plus grand carré clair, mesuré sur une version
/// réduite (dans le téléphone).
typedef AnalyzedImage = ({
  int width,
  int height,
  ({int x, int y, int side})? lightSquare,
  int sampleWidth,
  int sampleHeight,
});

/// Analyse d'une image (décodage réel ; fausse analyse en test).
final templateImageAnalyzerProvider =
    Provider<Future<AnalyzedImage> Function(Uint8List bytes)>(
      (ref) => analyzeTemplateImage,
    );

/// Largeur de l'image réduite pour chercher le carré clair.
const _sampleWidth = 240;

Future<AnalyzedImage> analyzeTemplateImage(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final width = descriptor.width;
  final height = descriptor.height;
  final sampleWidth = width < _sampleWidth ? width : _sampleWidth;
  final sampleHeight = (height * sampleWidth / width).round().clamp(1, height);
  final codec = await descriptor.instantiateCodec(
    targetWidth: sampleWidth,
    targetHeight: sampleHeight,
  );
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData();
  frame.image.dispose();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  final square = data == null
      ? null
      : largestLightSquare(
          data.buffer.asUint8List(),
          sampleWidth,
          sampleHeight,
        );
  return (
    width: width,
    height: height,
    lightSquare: square,
    sampleWidth: sampleWidth,
    sampleHeight: sampleHeight,
  );
}
