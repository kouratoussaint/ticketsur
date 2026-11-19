import 'package:ticketsur/features/announcements/domain/announcement.dart';
import 'package:ticketsur/features/support/domain/support.dart';

/// Demande type.
SupportRequest supportRequest({
  String id = 'r1',
  String subject = 'Ticket introuvable',
  SupportStatus status = SupportStatus.open,
  bool unread = false,
  String? requesterName,
}) => SupportRequest(
  id: id,
  subject: subject,
  category: SupportCategory.problem,
  status: status,
  unread: unread,
  createdAt: DateTime.utc(2030, 5, 30, 9),
  lastMessageAt: DateTime.utc(2030, 5, 31, 10),
  requesterName: requesterName,
  requesterEmail: requesterName == null ? null : 'awa@exemple.bf',
  messages: requesterName == null ? 0 : 2,
);

/// Support en mémoire : un fil par demande.
class FakeSupportRepository implements SupportRepository {
  new({List<SupportRequest>? requests, this.failure}) {
    for (final r in requests ?? const <SupportRequest>[]) {
      _requests[r.id] = r;
      _threads[r.id] = [
        SupportMessage(
          id: '${r.id}-m1',
          fromAdmin: false,
          authorName: 'Awa Ouédraogo',
          body: 'Bonjour, mon ticket ne s’affiche plus.',
          createdAt: r.createdAt,
        ),
      ];
    }
  }

  final Map<String, SupportRequest> _requests = {};
  final Map<String, List<SupportMessage>> _threads = {};

  /// Échec renvoyé par toutes les écritures.
  SupportFailure? failure;

  /// Appels reçus (pour les vérifications).
  final List<String> calls = [];

  /// Dernière création reçue.
  ({String subject, SupportCategory category, String body})? created;

  int _next = 0;

  SupportRequest _copy(
    SupportRequest r, {
    SupportStatus? status,
    bool? unread,
  }) => SupportRequest(
    id: r.id,
    subject: r.subject,
    category: r.category,
    status: status ?? r.status,
    unread: unread ?? r.unread,
    createdAt: r.createdAt,
    lastMessageAt: r.lastMessageAt,
    requesterName: r.requesterName,
    requesterEmail: r.requesterEmail,
    organizationName: r.organizationName,
    messages: r.messages,
  );

  @override
  Future<List<SupportRequest>> myRequests() async {
    calls.add('mine');
    return _requests.values.toList();
  }

  @override
  Future<String> create({
    required String subject,
    required SupportCategory category,
    required String body,
    String? organizationId,
  }) async {
    calls.add('create');
    if (failure case final f?) throw f;
    created = (subject: subject, category: category, body: body);
    final id = 'new-${_next++}';
    final now = DateTime.utc(2030, 6, 1, 12);
    _requests[id] = SupportRequest(
      id: id,
      subject: subject,
      category: category,
      status: SupportStatus.open,
      unread: false,
      createdAt: now,
      lastMessageAt: now,
    );
    _threads[id] = [
      SupportMessage(
        id: '$id-m1',
        fromAdmin: false,
        authorName: 'Vous',
        body: body,
        createdAt: now,
      ),
    ];
    return id;
  }

  @override
  Future<List<SupportMessage>> thread(String requestId) async {
    calls.add('thread:$requestId');
    final messages = _threads[requestId];
    if (messages == null) throw SupportFailure.notFound;
    if (_requests[requestId] case final r?) {
      _requests[requestId] = _copy(r, unread: false);
    }
    return [...messages];
  }

  /// Les réponses de la console passent par [adminMode].
  bool adminMode = false;

  @override
  Future<SupportStatus> reply(String requestId, String body) async {
    calls.add('reply:$requestId');
    if (failure case final f?) throw f;
    final r = _requests[requestId];
    if (r == null) throw SupportFailure.notFound;
    _threads[requestId]!.add(
      SupportMessage(
        id: '$requestId-m${_threads[requestId]!.length + 1}',
        fromAdmin: adminMode,
        authorName: adminMode ? 'Support Tikéo' : 'Awa Ouédraogo',
        body: body,
        createdAt: DateTime.utc(2030, 6, 1, 12),
      ),
    );
    final status = adminMode ? SupportStatus.answered : SupportStatus.open;
    _requests[requestId] = _copy(r, status: status);
    return status;
  }

  @override
  Future<void> close(String requestId) async {
    calls.add('close:$requestId');
    if (failure case final f?) throw f;
    final r = _requests[requestId];
    if (r == null) throw SupportFailure.notFound;
    _requests[requestId] = _copy(r, status: SupportStatus.closed);
  }

  @override
  Future<List<SupportRequest>> adminRequests({
    SupportStatus? status,
    String search = '',
    int offset = 0,
    int limit = 30,
  }) async {
    calls.add('admin:${status?.wireName ?? 'all'}:$search');
    final all = [
      for (final r in _requests.values)
        if (status == null || r.status == status)
          if (search.isEmpty ||
              r.subject.toLowerCase().contains(search.toLowerCase()))
            r,
    ];
    return all.skip(offset).take(limit).toList();
  }

  @override
  Future<SupportCounts> adminCounts() async => (
    open: _requests.values.where((r) => r.status == SupportStatus.open).length,
    unread: _requests.values.where((r) => r.unread).length,
    answered: _requests.values
        .where((r) => r.status == SupportStatus.answered)
        .length,
  );
}

/// Annonce type.
Announcement announcement({
  String id = 'a1',
  String title = 'Maintenance samedi',
  String body = 'Tikéo sera indisponible de 2 h à 3 h.',
  bool important = false,
  Set<AnnouncementAudience> audiences = const {AnnouncementAudience.users},
  bool active = true,
}) => Announcement(
  id: id,
  title: title,
  body: body,
  important: important,
  startsAt: DateTime.utc(2030, 5, 31, 8),
  endsAt: DateTime.utc(2030, 6, 7, 8),
  audiences: audiences,
  active: active,
  authorName: 'Toussaint',
);

/// Annonces en mémoire.
class FakeAnnouncementRepository implements AnnouncementRepository {
  new({List<Announcement>? mine, List<Announcement>? all, this.failure})
    : _mine = [...?mine],
      _all = [...?all];

  final List<Announcement> _mine;
  final List<Announcement> _all;
  AnnouncementFailure? failure;

  /// Dernière publication reçue.
  ({
    String title,
    String body,
    Set<AnnouncementAudience> audiences,
    bool important,
    DateTime? endsAt,
  })?
  published;

  final List<String> archived = [];

  @override
  Future<List<Announcement>> mine() async {
    if (failure case final f?) throw f;
    return [..._mine];
  }

  @override
  Future<List<Announcement>> all({int offset = 0, int limit = 50}) async =>
      _all.skip(offset).take(limit).toList();

  @override
  Future<String> publish({
    required String title,
    required String body,
    required Set<AnnouncementAudience> audiences,
    required bool important,
    DateTime? endsAt,
  }) async {
    if (failure case final f?) throw f;
    published = (
      title: title,
      body: body,
      audiences: {...audiences},
      important: important,
      endsAt: endsAt,
    );
    final created = Announcement(
      id: 'pub-${_all.length}',
      title: title.trim(),
      body: body.trim(),
      important: important,
      startsAt: DateTime.utc(2030, 6),
      endsAt: endsAt,
      audiences: {...audiences},
    );
    _all.insert(0, created);
    return created.id;
  }

  @override
  Future<void> archive(String id) async {
    if (failure case final f?) throw f;
    archived.add(id);
    final i = _all.indexWhere((a) => a.id == id);
    if (i >= 0) {
      final a = _all[i];
      _all[i] = Announcement(
        id: a.id,
        title: a.title,
        body: a.body,
        important: a.important,
        startsAt: a.startsAt,
        endsAt: a.endsAt,
        audiences: a.audiences,
        archivedAt: DateTime.utc(2030, 6),
        active: false,
        authorName: a.authorName,
      );
    }
  }
}
