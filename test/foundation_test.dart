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
  });
}
