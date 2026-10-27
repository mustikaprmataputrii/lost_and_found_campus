part of '../../main.dart';

class LocalDataSnapshot {
  final List<BarangItem> reports;
  final List<SesiChat> chats;
  final List<NotifikasiItem> notifications;
  final List<AdminUser> users;
  final bool fromCache;

  const LocalDataSnapshot({
    required this.reports,
    required this.chats,
    required this.notifications,
    this.users = const [],
    this.fromCache = false,
  });

  bool get hasAnyData =>
      reports.isNotEmpty ||
      chats.isNotEmpty ||
      notifications.isNotEmpty ||
      users.isNotEmpty;
}

class LocalDataRepository {
  static const _reportsBoxName = 'temu_reports';
  static const _chatsBoxName = 'temu_chats';
  static const _notificationsBoxName = 'temu_notifications';
  static const _uploadQueueBoxName = 'temu_upload_queue';
  static const _draftBoxName = 'temu_report_drafts';
  static const _metaBoxName = 'temu_cache_meta';

  static late Box<Map> _reportsBox;
  static late Box<Map> _chatsBox;
  static late Box<Map> _notificationsBox;
  static late Box<Map> _uploadQueueBox;
  static late Box<Map> _draftBox;
  static late Box<String> _metaBox;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      Hive.init('temu_web_storage');
    } else {
      await Hive.initFlutter();
    }
    _reportsBox = await Hive.openBox<Map>(_reportsBoxName);
    _chatsBox = await Hive.openBox<Map>(_chatsBoxName);
    _notificationsBox = await Hive.openBox<Map>(_notificationsBoxName);
    _uploadQueueBox = await Hive.openBox<Map>(_uploadQueueBoxName);
    _draftBox = await Hive.openBox<Map>(_draftBoxName);
    _metaBox = await Hive.openBox<String>(_metaBoxName);
    _initialized = true;
  }

  Future<LocalDataSnapshot> load({bool seedIfEmpty = true}) async {
    await initialize();

    var reports =
        _reportsBox.values.map((value) => BarangItem.fromMap(value)).toList();
    if (seedIfEmpty && reports.isEmpty) {
      reports = MockDataRepository.initialBarang();
      await saveReports(reports);
    }

    var chats =
        _chatsBox.values.map((value) => SesiChat.fromMap(value)).toList();
    if (seedIfEmpty && chats.isEmpty) {
      chats = MockDataRepository.initialChats(reports);
      await saveChats(chats);
    }

    var notifications = _notificationsBox.values
        .map((value) => NotifikasiItem.fromMap(value))
        .toList();
    if (seedIfEmpty && notifications.isEmpty) {
      notifications = MockDataRepository.initialNotifications();
      await saveNotifications(notifications);
    }

    return LocalDataSnapshot(
      reports: reports,
      chats: chats,
      notifications: notifications,
    );
  }

  Future<void> saveAll({
    required List<BarangItem> reports,
    required List<SesiChat> chats,
    required List<NotifikasiItem> notifications,
  }) async {
    await Future.wait([
      saveReports(reports),
      saveChats(chats),
      saveNotifications(notifications),
    ]);
  }

  Future<void> saveReports(List<BarangItem> reports) async {
    await _reportsBox.clear();
    for (final report in reports) {
      await _reportsBox.put(report.id, report.toMap());
    }
  }

  Future<void> saveReport(BarangItem report) async {
    await initialize();
    await _reportsBox.put(report.id, report.toMap());
  }

  Future<void> saveChats(List<SesiChat> chats) async {
    await _chatsBox.clear();
    for (final chat in chats) {
      await _chatsBox.put(chat.id, chat.toMap());
    }
  }

  Future<void> saveNotifications(List<NotifikasiItem> notifications) async {
    await _notificationsBox.clear();
    for (var index = 0; index < notifications.length; index++) {
      await _notificationsBox.put(
        'notification_$index',
        notifications[index].toMap(),
      );
    }
  }

  Future<List<PendingUpload>> loadUploadQueue() async {
    await initialize();
    final queue = <PendingUpload>[];
    for (final value in _uploadQueueBox.values) {
      try {
        queue.add(PendingUpload.fromMap(value));
      } catch (error) {
        debugPrint('Melewati item antrean upload yang rusak: $error');
      }
    }
    queue.sort((a, b) => a.nextAttemptAt.compareTo(b.nextAttemptAt));
    return queue;
  }

  Future<void> savePendingUpload(PendingUpload item) async {
    await initialize();
    await _uploadQueueBox.put(item.reportId, item.toMap());
  }

  Future<void> removePendingUpload(String reportId) async {
    await initialize();
    await _uploadQueueBox.delete(reportId);
  }

  Future<ReportDraft?> loadReportDraft(String email) async {
    await initialize();
    final owner = _normalizeEmail(email);
    final raw = _draftBox.get(owner);
    if (raw == null) return null;
    try {
      final draft = ReportDraft.fromMap(raw);
      return _normalizeEmail(draft.email) == owner ? draft : null;
    } catch (error) {
      debugPrint('Melewati draft laporan yang rusak: $error');
      return null;
    }
  }

  Future<void> saveReportDraft(ReportDraft draft) async {
    await initialize();
    await _draftBox.put(_normalizeEmail(draft.email), draft.toMap());
  }

  Future<void> deleteReportDraft(String email) async {
    await initialize();
    await _draftBox.delete(_normalizeEmail(email));
  }

  Future<void> markCacheOwner(String email) async {
    await initialize();
    await _metaBox.put('owner_email', _normalizeEmail(email));
  }

  Future<bool> matchesCacheOwner(String email) async {
    await initialize();
    return _metaBox.get('owner_email') == _normalizeEmail(email);
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();
}
