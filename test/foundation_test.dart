import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_campus/main.dart';

class _FakeLocal extends LocalDataRepository {
  _FakeLocal({this.cached, this.cacheOwned = true});

  final LocalDataSnapshot? cached;
  bool saveAllCalled = false;
  bool saveReportCalled = false;
  bool cacheOwned;

  @override
  Future<void> markCacheOwner(String email) async {
    cacheOwned = true;
  }

  @override
  Future<bool> matchesCacheOwner(String email) async => cacheOwned;

  @override
  Future<LocalDataSnapshot> load({bool seedIfEmpty = true}) async {
    return cached ??
        const LocalDataSnapshot(
          reports: [],
          chats: [],
          notifications: [],
        );
  }

  @override
  Future<void> saveAll({
    required List<BarangItem> reports,
    required List<SesiChat> chats,
    required List<NotifikasiItem> notifications,
  }) async {
    saveAllCalled = true;
  }

  @override
  Future<void> saveReport(BarangItem report) async {
    saveReportCalled = true;
  }
}

class _FakeRemote extends ApiService {
  _FakeRemote({this.loadError, this.saveError});

  final Object? loadError;
  final Object? saveError;
  bool saveAllCalled = false;

  @override
  Future<LocalDataSnapshot> load({required String email}) async {
    if (loadError != null) throw loadError!;
    return const LocalDataSnapshot(
      reports: [],
      chats: [],
      notifications: [],
    );
  }

  @override
  Future<void> saveAll({
    required String email,
    required String nama,
    required List<BarangItem> reports,
    required List<SesiChat> chats,
    required List<NotifikasiItem> notifications,
  }) async {
    if (saveError != null) throw saveError!;
    saveAllCalled = true;
  }
}

BarangItem _barangUji() => BarangItem(
      id: 'foundation-report',
      nama: 'Kunci uji',
      lokasi: 'Perpustakaan UIN',
      deskripsi: 'Kunci dengan gantungan biru.',
      jenis: JenisLaporan.hilang,
      pelapor: 'Mahasiswa Uji',
      kontak: '081234567890',
      tanggal: DateTime(2026, 10, 26),
      pemilikEmail: 'owner@student.uin-malang.ac.id',
    );

void main() {
  group('Fondasi upload dan cache', () {
    test('saveAll menyimpan cache lalu meneruskan error API', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote(saveError: Exception('API offline'));
      final repository = AppDataRepository(local: local, remote: remote);

      await expectLater(
        repository.saveAll(
          email: 'owner@student.uin-malang.ac.id',
          nama: 'Mahasiswa Uji',
          reports: const <BarangItem>[],
          chats: const <SesiChat>[],
          notifications: const <NotifikasiItem>[],
        ),
        throwsA(isA<Exception>()),
      );

      expect(local.saveAllCalled, isTrue);
    });

    test('load memakai cache saat API gagal', () async {
      final local = _FakeLocal(
        cached: LocalDataSnapshot(
          reports: [_barangUji()],
          chats: const [],
          notifications: const [],
        ),
      );
      final remote = _FakeRemote(loadError: Exception('API offline'));
      final repository = AppDataRepository(local: local, remote: remote);

      final result = await repository.load(
        email: 'owner@student.uin-malang.ac.id',
      );

      expect(result.fromCache, isTrue);
      expect(result.reports, hasLength(1));
      expect(result.reports.single.nama, 'Kunci uji');
    });

    test('load tidak memakai cache milik akun lain', () async {
      final local = _FakeLocal(
        cached: LocalDataSnapshot(
          reports: [_barangUji()],
          chats: const [],
          notifications: const [],
        ),
        cacheOwned: false,
      );
      final remote = _FakeRemote(loadError: Exception('API offline'));
      final repository = AppDataRepository(local: local, remote: remote);

      await expectLater(
        repository.load(email: 'other@student.uin-malang.ac.id'),
        throwsA(
          predicate(
            (Object error) => error.toString().contains('API offline'),
          ),
        ),
      );
    });

    test('loadCache mengembalikan null saat cache milik akun lain', () async {
      final local = _FakeLocal(
        cached: LocalDataSnapshot(
          reports: [_barangUji()],
          chats: const [],
          notifications: const [],
        ),
        cacheOwned: false,
      );
      final repository = AppDataRepository(
        local: local,
        remote: _FakeRemote(),
      );

      final result = await repository.loadCache(
        email: 'other@student.uin-malang.ac.id',
      );

      expect(result, isNull);
    });

    test('load meneruskan error API saat cache kosong', () async {
      final local = _FakeLocal(
        cached: const LocalDataSnapshot(
          reports: [],
          chats: [],
          notifications: [],
        ),
      );
      final remote = _FakeRemote(loadError: Exception('API offline'));
      final repository = AppDataRepository(local: local, remote: remote);

      await expectLater(
        repository.load(email: 'owner@student.uin-malang.ac.id'),
        throwsA(
          predicate(
            (Object error) => error.toString().contains('API offline'),
          ),
        ),
      );
    });

    test('createReport menyimpan ke server sebelum cache', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote();
      final repository = AppDataRepository(local: local, remote: remote);

      await repository.createReport(
        email: 'owner@student.uin-malang.ac.id',
        nama: 'Mahasiswa Uji',
        report: _barangUji(),
      );

      expect(remote.saveAllCalled, isTrue);
      expect(local.saveReportCalled, isTrue);
    });

    test('createReport tidak menulis cache saat server gagal', () async {
      final local = _FakeLocal();
      final remote = _FakeRemote(saveError: Exception('API offline'));
      final repository = AppDataRepository(local: local, remote: remote);

      await expectLater(
        repository.createReport(
          email: 'owner@student.uin-malang.ac.id',
          nama: 'Mahasiswa Uji',
          report: _barangUji(),
        ),
        throwsA(isA<Exception>()),
      );

      expect(local.saveReportCalled, isFalse);
    });

    test('load tanpa cache melempar error saat API gagal', () async {
      final local = _FakeLocal(
        cached: LocalDataSnapshot(
          reports: [_barangUji()],
          chats: const [],
          notifications: const [],
        ),
      );
      final remote = _FakeRemote(loadError: Exception('API offline'));
      final repository = AppDataRepository(local: local, remote: remote);

      await expectLater(
        repository.load(
          email: 'owner@student.uin-malang.ac.id',
          izinkanCache: false,
        ),
        throwsA(
          predicate(
            (Object error) => error.toString().contains('API offline'),
          ),
        ),
      );
    });
  });

  group('Ringkasan dashboard', () {
    test('menghitung temuan aktif dan pesan belum dibaca', () {
      final snapshot = LocalDataSnapshot(
        reports: [
          _barangUji(),
          BarangItem(
            id: 'found-active',
            nama: 'Dompet ditemukan',
            lokasi: 'Gedung A',
            deskripsi: 'Dompet hitam.',
            jenis: JenisLaporan.ditemukan,
            pelapor: 'Mahasiswa Uji',
            kontak: '081234567890',
            tanggal: DateTime(2026, 10, 26),
          ),
          BarangItem(
            id: 'found-done',
            nama: 'Kunci selesai',
            lokasi: 'Gedung B',
            deskripsi: 'Sudah diklaim.',
            jenis: JenisLaporan.ditemukan,
            pelapor: 'Mahasiswa Uji',
            kontak: '081234567890',
            tanggal: DateTime(2026, 10, 26),
            status: StatusBarang.selesai,
          ),
        ],
        chats: [
          SesiChat(
            id: 'chat-uji',
            barang: _barangUji(),
            pesanList: const [],
            unreadCount: 2,
          ),
        ],
        notifications: [
          NotifikasiItem(
            title: 'Klaim baru',
            message: 'Ada yang mengajukan klaim.',
            waktu: DateTime(2026, 10, 27),
          ),
        ],
      );

      final ringkasan = RingkasanDashboard.dariSnapshot(snapshot);

      expect(ringkasan.temuanAktif, 1);
      expect(ringkasan.pesanBaru, 2);
      expect(ringkasan.judulPesan, 'Klaim baru');
      expect(ringkasan.isiPesan, 'Ada yang mengajukan klaim.');
      expect(ringkasan.dariCache, isFalse);
    });

    test('menampilkan pesan kosong saat tidak ada notifikasi', () {
      final ringkasan = RingkasanDashboard.dariSnapshot(
        const LocalDataSnapshot(
          reports: [],
          chats: [],
          notifications: [],
        ),
      );

      expect(ringkasan.temuanAktif, 0);
      expect(ringkasan.pesanBaru, 0);
      expect(ringkasan.judulPesan, 'Tidak ada pesan baru');
    });
  });
}
