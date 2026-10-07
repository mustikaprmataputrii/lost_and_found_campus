part of '../../main.dart';

class LocalDataSnapshot {
  final List<BarangItem> reports;
  final List<SesiChat> chats;
  final List<NotifikasiItem> notifications;

  const LocalDataSnapshot({
    required this.reports,
    required this.chats,
    required this.notifications,
  });
}

class LocalDataRepository {
  static const _reportsBoxName = 'temu_reports';
  static const _chatsBoxName = 'temu_chats';
  static const _notificationsBoxName = 'temu_notifications';

  static late Box<Map> _reportsBox;
  static late Box<Map> _chatsBox;
  static late Box<Map> _notificationsBox;
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
    _initialized = true;
  }

  Future<LocalDataSnapshot> load() async {
    await initialize();

    var reports =
        _reportsBox.values.map((value) => BarangItem.fromMap(value)).toList();
    if (reports.isEmpty) {
      reports = MockDataRepository.initialBarang();
      await saveReports(reports);
    }

    var chats =
        _chatsBox.values.map((value) => SesiChat.fromMap(value)).toList();
    if (chats.isEmpty) {
      chats = MockDataRepository.initialChats(reports);
      await saveChats(chats);
    }

    var notifications = _notificationsBox.values
        .map((value) => NotifikasiItem.fromMap(value))
        .toList();
    if (notifications.isEmpty) {
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
}
