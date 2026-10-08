part of '../../main.dart';

class AppDataRepository {
  final LocalDataRepository _local = LocalDataRepository();
  final ApiService _remote = ApiService();

  Future<LocalDataSnapshot> load({required String email}) async {
    try {
      final remoteData = await _remote.load(email: email);
      await _local.saveAll(
        reports: remoteData.reports,
        chats: remoteData.chats,
        notifications: remoteData.notifications,
      );
      return remoteData;
    } catch (_) {
      // Server adalah sumber data bersama. Jangan mengembalikan cache akun
      // sebelumnya ketika API sedang offline.
      rethrow;
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
    await _remote.login(email: email, nim: nim, nama: nama);
  }

  Future<void> updatePresence({
    required String email,
    required bool isOnline,
  }) async {
    try {
      await _remote.updatePresence(email: email, isOnline: isOnline);
    } catch (_) {
      // Presence tidak menghalangi penggunaan lokal saat API sementara offline.
    }
  }

  Future<void> deleteReport({
    required String email,
    required String reportId,
  }) {
    return _remote.deleteReport(email: email, reportId: reportId);
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
