import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show AsyncNotifierProviderFamily;
import 'package:share_plus/share_plus.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';

/// Dépôt des tickets (Supabase au démarrage, faux en test).
final ticketRepositoryProvider = Provider<TicketRepository>(
  (ref) => throw UnimplementedError(
    'ticketRepositoryProvider doit être surchargé dans ProviderScope.',
  ),
);

/// Fichier à partager, construit en mémoire.
typedef SharedFile = ({Uint8List bytes, String name, String mimeType});

/// Partage de fichiers (image, PDF) par le menu Android, sous leur vrai nom ;
/// remplacé en test.
final shareFilesProvider =
    Provider<Future<void> Function(List<SharedFile> files, {String? text})>(
      (ref) => (files, {text}) async {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              for (final f in files)
                XFile.fromData(f.bytes, mimeType: f.mimeType),
            ],
            fileNameOverrides: [for (final f in files) f.name],
            text: text,
          ),
        );
      },
    );

/// Critères de la liste des tickets.
typedef TicketQuery = ({String eventId, TicketStatus? status, String search});

/// Taille d'une page de tickets.
const int ticketPageSize = 40;

/// Tickets d'un événement, paginés.
class TicketListController extends AsyncNotifier<TicketPage> {
  new(this.query);

  final TicketQuery query;

  TicketRepository get _repository => ref.read(ticketRepositoryProvider);

  @override
  Future<TicketPage> build() => _repository.list(
    query.eventId,
    status: query.status,
    search: query.search,
    limit: ticketPageSize,
  );

  /// Charge la page suivante, s'il y en a une.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.items.length >= current.total) return;
    final next = await _repository.list(
      query.eventId,
      status: query.status,
      search: query.search,
      limit: ticketPageSize,
      offset: current.items.length,
    );
    state = AsyncData(
      TicketPage(items: [...current.items, ...next.items], total: next.total),
    );
  }
}

/// Liste des tickets pour une requête donnée.
final AsyncNotifierProviderFamily<TicketListController, TicketPage, TicketQuery>
ticketListProvider = AsyncNotifierProvider.autoDispose
    .family<TicketListController, TicketPage, TicketQuery>(
      TicketListController.new,
      retry: (retryCount, error) => null,
    );

/// Jetons connus pendant la session (émission ou ré-export), par ticket.
/// Jamais écrits sur l'appareil ; vidés à chaque changement de compte.
class TicketSecretsController extends Notifier<Map<String, TicketSecret>> {
  @override
  Map<String, TicketSecret> build() {
    ref.watch(currentUserProvider.select((user) => user.value?.id));
    return const {};
  }

  void addAll(Iterable<TicketSecret> secrets) {
    state = {...state, for (final s in secrets) s.ticketId: s};
  }

  void forget(String ticketId) {
    state = {...state}..remove(ticketId);
  }
}

final NotifierProvider<TicketSecretsController, Map<String, TicketSecret>>
ticketSecretsProvider =
    NotifierProvider<TicketSecretsController, Map<String, TicketSecret>>(
      TicketSecretsController.new,
    );

/// Événement choisi dans l'onglet Tickets (remis à zéro si l'organisation
/// active change).
class SelectedTicketEvent extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(activeOrganizationProvider.select((o) => o?.id));
    return null;
  }

  /// Événement affiché.
  String? get eventId => state;
  set eventId(String? value) => state = value;
}

final NotifierProvider<SelectedTicketEvent, String?>
selectedTicketEventProvider = NotifierProvider<SelectedTicketEvent, String?>(
  SelectedTicketEvent.new,
);

/// Opérations sur les tickets, avec mise à jour des listes et compteurs.
class TicketActions {
  new(this._ref);

  final Ref _ref;

  TicketRepository get _repository => _ref.read(ticketRepositoryProvider);

  void _refresh(String eventId) {
    _ref
      ..invalidate(ticketListProvider)
      ..invalidate(categoriesProvider(eventId));
  }

  /// Émet un lot ; les jetons sont gardés pour la session.
  /// Lève une [TicketFailure] en cas d'échec.
  Future<List<TicketSecret>> issue(
    String eventId,
    String categoryId,
    int quantity, {
    required String categoryName,
  }) async {
    final secrets = await _repository.issue(
      eventId,
      categoryId,
      quantity,
      categoryName: categoryName,
    );
    _ref.read(ticketSecretsProvider.notifier).addAll(secrets);
    _refresh(eventId);
    return secrets;
  }

  /// Ré-export audité ; par paquets de [maxExportSize].
  Future<List<TicketSecret>> export(List<String> ticketIds) async {
    final result = <TicketSecret>[];
    for (var i = 0; i < ticketIds.length; i += maxExportSize) {
      final end = i + maxExportSize > ticketIds.length
          ? ticketIds.length
          : i + maxExportSize;
      result.addAll(await _repository.export(ticketIds.sublist(i, end)));
    }
    _ref.read(ticketSecretsProvider.notifier).addAll(result);
    return result;
  }

  /// Annule un ticket ; son jeton est oublié.
  Future<TicketStatus> revoke(
    String eventId,
    String ticketId, {
    String? reason,
  }) async {
    final status = await _repository.revoke(ticketId, reason: reason);
    if (status == TicketStatus.revoked) {
      _ref.read(ticketSecretsProvider.notifier).forget(ticketId);
    }
    _refresh(eventId);
    return status;
  }
}

final Provider<TicketActions> ticketActionsProvider = Provider<TicketActions>(
  TicketActions.new,
);
