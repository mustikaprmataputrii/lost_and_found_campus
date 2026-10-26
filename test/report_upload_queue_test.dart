import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_campus/main.dart';

class _QueueLocal extends LocalDataRepository {
  final Map<String, PendingUpload> queue = {};
  bool saveReportCalled = false;

  @override
  Future<List<PendingUpload>> loadUploadQueue() async {
    final items = queue.values.toList()
      ..sort((a, b) => a.nextAttemptAt.compareTo(b.nextAttemptAt));
    return items;
  }

  @override
  Future<void> savePendingUpload(PendingUpload item) async {
    queue[item.reportId] = item;
  }

  @override
  Future<void> removePendingUpload(String reportId) async {
    queue.remove(reportId);
  }

  @override
  Future<void> saveReport(BarangItem report) async {
    saveReportCalled = true;
  }
}

class _QueueRemote extends ApiService {
  _QueueRemote({this.error});

  Object? error;
  int saveCalls = 0;

  @override
  Future<void> saveAll({
    required String email,
    required String nama,
    required List<BarangItem> reports,
    required List<SesiChat> chats,
    required List<NotifikasiItem> notifications,
  }) async {
    saveCalls++;
    if (error != null) throw error!;
  }
}

BarangItem _barangUji({String id = 'queue-report'}) => BarangItem(
      id: id,
      nama: 'Kunci antrean',
      lokasi: 'Perpustakaan UIN',
      deskripsi: 'Kunci dengan gantungan biru.',
      jenis: JenisLaporan.hilang,
      pelapor: 'Mahasiswa Uji',
      kontak: '081234567890',
      tanggal: DateTime(2026, 10, 26),
      pemilikEmail: 'owner@student.uin-malang.ac.id',
    );

PendingUpload _pendingUpload({
  int attempts = 1,
  DateTime? nextAttemptAt,
  String email = 'owner@student.uin-malang.ac.id',
  String reportId = 'queue-report',
}) {
  final report = _barangUji(id: reportId);
  return PendingUpload(
    reportId: report.id,
    email: email,
    nama: 'Mahasiswa Uji',
    report: report,
    attempts: attempts,
    nextAttemptAt:
        nextAttemptAt ?? DateTime.now().subtract(const Duration(seconds: 1)),
  );
}

void main() {
  group('ReportUploadQueue', () {
    test('submit langsung mengunggah dan menyimpan cache', () async {
      final local = _QueueLocal();
      final remote = _QueueRemote();
      final queue = ReportUploadQueue(remote: remote, local: local);

      final result = await queue.submit(
        email: 'owner@student.uin-malang.ac.id',
        nama: 'Mahasiswa Uji',
        report: _barangUji(),
      );

      expect(result.uploaded, isTrue);
      expect(remote.saveCalls, 1);
      expect(local.saveReportCalled, isTrue);
      expect(local.queue, isEmpty);
    });

    test('submit menjadwalkan retry saat error jaringan', () async {
      final local = _QueueLocal();
      final remote = _QueueRemote(error: Exception('offline'));
      final queue = ReportUploadQueue(remote: remote, local: local);

      final result = await queue.submit(
        email: 'owner@student.uin-malang.ac.id',
        nama: 'Mahasiswa Uji',
        report: _barangUji(),
      );

      expect(result.uploaded, isFalse);
      expect(local.queue, hasLength(1));
      final pending = local.queue.values.single;
      expect(pending.attempts, 1);
      expect(pending.nextAttemptAt.isAfter(DateTime.now()), isTrue);
      expect(pending.lastError, contains('offline'));
      expect(local.saveReportCalled, isFalse);
      expect(await queue.pendingCount(), 1);
    });

    test('submit meneruskan error validasi tanpa masuk antrean', () async {
      final local = _QueueLocal();
      final remote =
          _QueueRemote(error: const ApiException(422, 'Tidak valid'));
      final queue = ReportUploadQueue(remote: remote, local: local);

      await expectLater(
        queue.submit(
          email: 'owner@student.uin-malang.ac.id',
          nama: 'Mahasiswa Uji',
          report: _barangUji(),
        ),
        throwsA(isA<ApiException>()),
      );

      expect(local.queue, isEmpty);
      expect(local.saveReportCalled, isFalse);
    });

    test('flush mengunggah item yang sudah jatuh tempo', () async {
      final local = _QueueLocal();
      final remote = _QueueRemote();
      final queue = ReportUploadQueue(remote: remote, local: local);
      local.queue[_barangUji().id] = _pendingUpload();

      final uploaded = await queue.flush();

      expect(uploaded, 1);
      expect(remote.saveCalls, 1);
      expect(local.saveReportCalled, isTrue);
      expect(local.queue, isEmpty);
    });

    test('flush hanya memproses antrean email yang diminta', () async {
      final local = _QueueLocal();
      final remote = _QueueRemote();
      final queue = ReportUploadQueue(remote: remote, local: local);
      local.queue['own'] = _pendingUpload(reportId: 'own');
      local.queue['other'] = _pendingUpload(
        reportId: 'other',
        email: 'other@student.uin-malang.ac.id',
      );

      final uploaded = await queue.flush(
        email: 'owner@student.uin-malang.ac.id',
      );

      expect(uploaded, 1);
      expect(local.queue.keys, contains('other'));
      expect(local.queue.keys, isNot(contains('own')));
      expect(
        await queue.pendingCount(email: 'owner@student.uin-malang.ac.id'),
        0,
      );
      expect(
        await queue.pendingCount(email: 'other@student.uin-malang.ac.id'),
        1,
      );
    });

    test('flush melewati item yang belum jatuh tempo', () async {
      final local = _QueueLocal();
      final remote = _QueueRemote();
      final queue = ReportUploadQueue(remote: remote, local: local);
      local.queue[_barangUji().id] = _pendingUpload(
        nextAttemptAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final uploaded = await queue.flush();

      expect(uploaded, 0);
      expect(remote.saveCalls, 0);
      expect(local.queue, hasLength(1));
    });

    test('flush memaksa item yang belum jatuh tempo', () async {
      final local = _QueueLocal();
      final remote = _QueueRemote();
      final queue = ReportUploadQueue(remote: remote, local: local);
      local.queue[_barangUji().id] = _pendingUpload(
        nextAttemptAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final uploaded = await queue.flush(force: true);

      expect(uploaded, 1);
      expect(remote.saveCalls, 1);
      expect(local.queue, isEmpty);
    });

    test('flush menaikkan attempts dan backoff saat gagal', () async {
      final local = _QueueLocal();
      final remote = _QueueRemote(error: Exception('offline'));
      final queue = ReportUploadQueue(remote: remote, local: local);
      local.queue[_barangUji().id] = _pendingUpload();

      final uploaded = await queue.flush();

      expect(uploaded, 0);
      final pending = local.queue.values.single;
      expect(pending.attempts, 2);
      expect(pending.nextAttemptAt.isAfter(DateTime.now()), isTrue);
      expect(pending.lastError, contains('offline'));
    });

    test('PendingUpload dapat disimpan dan dibaca kembali', () {
      final item = _pendingUpload();
      final restored = PendingUpload.fromMap(item.toMap());

      expect(restored.reportId, item.reportId);
      expect(restored.report.nama, item.report.nama);
      expect(restored.report.pemilikEmail, item.report.pemilikEmail);
      expect(restored.attempts, item.attempts);
      expect(restored.nextAttemptAt, item.nextAttemptAt);
    });

    test('flush menghapus item yang gagal permanen', () async {
      final local = _QueueLocal();
      final remote = _QueueRemote(error: const ApiException(400, 'Ditolak'));
      final queue = ReportUploadQueue(remote: remote, local: local);
      local.queue[_barangUji().id] = _pendingUpload();

      final uploaded = await queue.flush();

      expect(uploaded, 0);
      expect(remote.saveCalls, 1);
      expect(local.queue, isEmpty);
    });
  });
}
