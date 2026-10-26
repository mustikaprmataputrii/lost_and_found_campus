part of '../../main.dart';

class ReportUploadQueue {
  final ApiService _remote;
  final LocalDataRepository _local;
  bool _isFlushing = false;

  ReportUploadQueue({ApiService? remote, LocalDataRepository? local})
      : _remote = remote ?? ApiService(),
        _local = local ?? LocalDataRepository();

  Future<ReportSubmissionResult> submit({
    required String email,
    required String nama,
    required BarangItem report,
  }) async {
    try {
      await _remote.saveAll(
        email: email,
        nama: nama,
        reports: [report],
        chats: const <SesiChat>[],
        notifications: const <NotifikasiItem>[],
      );
      await _saveLocal(report);
      return const ReportSubmissionResult.uploaded();
    } catch (error) {
      if (!_isRetryable(error)) rethrow;

      // Gagal karena jaringan/server sementara: simpan ke antrean agar dapat
      // dicoba lagi saat aplikasi kembali aktif.
      final pending = PendingUpload(
        reportId: report.id,
        email: email,
        nama: nama,
        report: report,
        attempts: 1,
        nextAttemptAt: DateTime.now().add(const Duration(seconds: 5)),
        lastError: error.toString(),
      );
      await _local.savePendingUpload(pending);
      return const ReportSubmissionResult.queued();
    }
  }

  Future<int> flush({bool force = false, String? email}) async {
    if (_isFlushing) return 0;
    _isFlushing = true;

    var uploaded = 0;
    try {
      final queue = await _local.loadUploadQueue();
      for (final item in queue) {
        // Antrean tidak boleh diproses oleh akun yang berbeda.
        if (email != null && item.email != email) {
          continue;
        }
        if (!force && item.nextAttemptAt.isAfter(DateTime.now())) {
          continue;
        }

        try {
          await _remote.saveAll(
            email: item.email,
            nama: item.nama,
            reports: [item.report],
            chats: const <SesiChat>[],
            notifications: const <NotifikasiItem>[],
          );
          await _saveLocal(item.report);
          await _local.removePendingUpload(item.reportId);
          uploaded++;
        } catch (error) {
          if (!_isRetryable(error)) {
            // Error validasi/otorisasi tidak akan berhasil jika diulang terus.
            await _local.removePendingUpload(item.reportId);
            debugPrint('Upload ${item.reportId} gagal permanen: $error');
            continue;
          }

          final attempts = item.attempts + 1;
          final delay = _retryDelaySeconds(attempts);
          await _local.savePendingUpload(item.copyWith(
            attempts: attempts,
            nextAttemptAt: DateTime.now().add(Duration(seconds: delay)),
            lastError: error.toString(),
          ));
          // Hentikan putaran ini; kemungkinan besar koneksi sedang bermasalah.
          break;
        }
      }
      return uploaded;
    } finally {
      _isFlushing = false;
    }
  }

  Future<int> pendingCount({String? email}) async {
    final queue = await _local.loadUploadQueue();
    if (email == null) return queue.length;
    return queue.where((item) => item.email == email).length;
  }

  Future<void> _saveLocal(BarangItem report) async {
    try {
      await _local.saveReport(report);
    } catch (error) {
      debugPrint('Gagal menyimpan laporan ke cache lokal: $error');
    }
  }

  int _retryDelaySeconds(int attempts) {
    const delays = [5, 15, 60, 300];
    final index = (attempts - 1).clamp(0, delays.length - 1).toInt();
    return delays[index];
  }

  bool _isRetryable(Object error) {
    if (error is ApiException) {
      return error.statusCode >= 500 ||
          error.statusCode == 408 ||
          error.statusCode == 429;
    }
    return true;
  }
}
