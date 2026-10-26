part of '../../main.dart';

class AppDataRepository {
  final LocalDataRepository _local;
  final ApiService _remote;

  AppDataRepository({LocalDataRepository? local, ApiService? remote})
      : _local = local ?? LocalDataRepository(),
        _remote = remote ?? ApiService();

  Future<LocalDataSnapshot> load({required String email}) async {
    try {
      final remoteData = await _remote.load(email: email);
      try {
        await _local.saveAll(
          reports: remoteData.reports,
          chats: remoteData.chats,
          notifications: remoteData.notifications,
        );
      } catch (error) {
        // Cache adalah lapisan pendukung; data server tetap yang paling baru.
        debugPrint('Gagal memperbarui cache lokal: $error');
      }
      return remoteData;
    } catch (error, stackTrace) {
      try {
        final cached = await _local.load(seedIfEmpty: false);
        if (cached.hasAnyData) {
          return LocalDataSnapshot(
            reports: cached.reports,
            chats: cached.chats,
            notifications: cached.notifications,
            users: cached.users,
            fromCache: true,
          );
        }
      } catch (cacheError) {
        debugPrint('Gagal membaca cache lokal: $cacheError');
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> saveAll({
    required String email,
    required String nama,
    required List<BarangItem> reports,
    required List<SesiChat> chats,
    required List<NotifikasiItem> notifications,
  }) async {
    try {
      await _local.saveAll(
        reports: reports,
        chats: chats,
        notifications: notifications,
      );
    } catch (error) {
      // Kegagalan cache tidak boleh menghalangi penyimpanan ke server.
      debugPrint('Gagal menyimpan cache lokal: $error');
    }

    // Error server harus sampai ke pemanggil agar UI dapat meminta pengguna
    // mencoba lagi, bukan menampilkan status berhasil palsu.
    await _remote.saveAll(
      email: email,
      nama: nama,
      reports: reports,
      chats: chats,
      notifications: notifications,
    );
  }

  Future<void> createReport({
    required String email,
    required String nama,
    required BarangItem report,
  }) async {
    await _remote.saveAll(
      email: email,
      nama: nama,
      reports: [report],
      chats: const <SesiChat>[],
      notifications: const <NotifikasiItem>[],
    );

    try {
      await _local.saveReport(report);
    } catch (error) {
      debugPrint('Gagal menyimpan laporan baru ke cache lokal: $error');
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

  Future<String> startChat({
    required String email,
    required String reportId,
  }) {
    return _remote.startChat(email: email, reportId: reportId);
  }

  Future<void> sendMessage({
    required String email,
    required String chatId,
    required String text,
  }) {
    return _remote.sendMessage(email: email, chatId: chatId, text: text);
  }

  Future<void> deleteMessage({
    required String email,
    required String messageId,
  }) {
    return _remote.deleteMessage(email: email, messageId: messageId);
  }

  Future<void> requestClaim({
    required String email,
    required String reportId,
  }) {
    return _remote.requestClaim(email: email, reportId: reportId);
  }

  Future<void> respondToClaim({
    required String email,
    required String reportId,
    required bool approve,
  }) {
    return _remote.respondToClaim(
      email: email,
      reportId: reportId,
      approve: approve,
    );
  }

  Future<void> markChatRead({
    required String email,
    required String chatId,
  }) {
    return _remote.markChatRead(email: email, chatId: chatId);
  }

  Future<void> markNotificationsRead({required String email}) {
    return _remote.markNotificationsRead(email: email);
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

  Future<void> updateAdminUser({
    required String token,
    required String currentEmail,
    required String nim,
    required String email,
    required String nama,
  }) {
    return _remote.updateAdminUser(
      token: token,
      currentEmail: currentEmail,
      nim: nim,
      email: email,
      nama: nama,
    );
  }

  Future<void> deleteAdminUser({
    required String token,
    required String email,
  }) {
    return _remote.deleteAdminUser(token: token, email: email);
  }
}
