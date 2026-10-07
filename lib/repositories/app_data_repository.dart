part of '../../main.dart';

class AppDataRepository {
  final LocalDataRepository _local = LocalDataRepository();
  final ApiService _remote = ApiService();

  Future<LocalDataSnapshot> load({required String email}) async {
    try {
      final remoteData = await _remote.load(email: email);
      final hasRemoteData = remoteData.reports.isNotEmpty ||
          remoteData.chats.isNotEmpty ||
          remoteData.notifications.isNotEmpty;

      if (!hasRemoteData) {
        final localData = await _local.load();
        await _remote.saveAll(
          email: email,
          nama: email.split('@').first,
          reports: localData.reports,
          chats: localData.chats,
          notifications: localData.notifications,
        );
        return localData;
      }

      await _local.saveAll(
        reports: remoteData.reports,
        chats: remoteData.chats,
        notifications: remoteData.notifications,
      );
      return remoteData;
    } catch (_) {
      return _local.load();
    }
  }

  Future<void> saveAll({
    required String email,
    required String nama,
    required List<BarangItem> reports,
    required List<SesiChat> chats,
    required List<NotifikasiItem> notifications,
  }) async {
    await _local.saveAll(
      reports: reports,
      chats: chats,
      notifications: notifications,
    );

    try {
      await _remote.saveAll(
        email: email,
        nama: nama,
        reports: reports,
        chats: chats,
        notifications: notifications,
      );
    } catch (_) {
      // Cache lokal tetap menjadi fallback ketika API sedang offline.
    }
  }

  Future<void> login({
    required String email,
    required String nim,
    required String nama,
  }) async {
    try {
      await _remote.login(email: email, nim: nim, nama: nama);
    } catch (_) {
      // Login lokal tetap dapat digunakan saat backend belum tersedia.
    }
  }

  Future<AdminLoginResult> adminLogin({
    required String email,
    required String password,
  }) {
    return _remote.adminLogin(email: email, password: password);
  }

  Future<LocalDataSnapshot> loadAdmin({required String token}) {
    return _remote.loadAdmin(token: token);
  }
}
