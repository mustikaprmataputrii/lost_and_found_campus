import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_campus/main.dart';

BarangItem _barang({
  required String id,
  required JenisLaporan jenis,
  String nama = 'Kunci motor Honda hitam',
  String lokasi = 'Perpustakaan Pusat',
  String deskripsi = 'Kunci motor dengan gantungan biru',
  DateTime? tanggal,
  String? pemilikEmail,
  StatusBarang status = StatusBarang.belumDiklaim,
}) =>
    BarangItem(
      id: id,
      nama: nama,
      lokasi: lokasi,
      deskripsi: deskripsi,
      jenis: jenis,
      pelapor: 'Mahasiswa Uji',
      kontak: '081234567890',
      tanggal: tanggal ?? DateTime(2026, 10, 20, 9),
      pemilikEmail: pemilikEmail,
      status: status,
    );

void main() {
  final service = CandidateMatchingService();
  final target = _barang(
    id: 'lost-1',
    jenis: JenisLaporan.hilang,
    pemilikEmail: 'pemilik@student.uin-malang.ac.id',
  );

  group('CandidateMatchingService', () {
    test('menemukan laporan jenis sebaliknya yang mirip', () {
      final found = _barang(
        id: 'found-1',
        jenis: JenisLaporan.ditemukan,
        tanggal: DateTime(2026, 10, 20, 10),
        pemilikEmail: 'penemu@student.uin-malang.ac.id',
      );

      final matches = service.findMatches(
        target: target,
        candidates: [found],
      );

      expect(matches, hasLength(1));
      expect(matches.single.report.id, 'found-1');
      expect(matches.single.score, closeTo(1, .001));
      expect(matches.single.percent, 100);
      expect(matches.single.reasons, contains('Nama barang mirip'));
      expect(matches.single.reasons, contains('Lokasi berdekatan'));
      expect(matches.single.reasons, contains('Waktu berdekatan'));
    });

    test('mengabaikan jenis sama, laporan selesai, dan pemilik sama', () {
      final sameType = _barang(
        id: 'same-type',
        jenis: JenisLaporan.hilang,
        pemilikEmail: 'lain@student.uin-malang.ac.id',
      );
      final completed = _barang(
        id: 'completed',
        jenis: JenisLaporan.ditemukan,
        status: StatusBarang.selesai,
        pemilikEmail: 'lain@student.uin-malang.ac.id',
      );
      final sameOwner = _barang(
        id: 'same-owner',
        jenis: JenisLaporan.ditemukan,
        pemilikEmail: 'pemilik@student.uin-malang.ac.id',
      );
      final valid = _barang(
        id: 'valid',
        jenis: JenisLaporan.ditemukan,
        pemilikEmail: 'penemu@student.uin-malang.ac.id',
      );

      final matches = service.findMatches(
        target: target,
        candidates: [sameType, completed, sameOwner, valid],
      );

      expect(matches.map((match) => match.report.id), ['valid']);
    });

    test('mengabaikan laporan yang tidak mirip', () {
      final unrelated = _barang(
        id: 'unrelated',
        jenis: JenisLaporan.ditemukan,
        nama: 'Botol minum biru',
        lokasi: 'Kantin Kampus 1',
        deskripsi: 'Botol plastik dengan tutup putih',
        tanggal: DateTime(2026, 9, 1),
        pemilikEmail: 'lain@student.uin-malang.ac.id',
      );

      final matches = service.findMatches(
        target: target,
        candidates: [unrelated],
      );

      expect(matches, isEmpty);
    });

    test('mengurutkan skor dan membatasi jumlah kandidat', () {
      final exact = _barang(
        id: 'exact',
        jenis: JenisLaporan.ditemukan,
        pemilikEmail: 'a@student.uin-malang.ac.id',
      );
      final twoDays = _barang(
        id: 'two-days',
        jenis: JenisLaporan.ditemukan,
        tanggal: DateTime(2026, 10, 18, 9),
        pemilikEmail: 'b@student.uin-malang.ac.id',
      );
      final otherLocation = _barang(
        id: 'other-location',
        jenis: JenisLaporan.ditemukan,
        lokasi: 'Gedung Rektorat',
        pemilikEmail: 'c@student.uin-malang.ac.id',
      );

      final matches = service.findMatches(
        target: target,
        candidates: [otherLocation, twoDays, exact],
        limit: 2,
      );

      expect(matches, hasLength(2));
      expect(matches[0].report.id, 'exact');
      expect(matches[1].report.id, 'two-days');
      expect(matches[0].score, greaterThan(matches[1].score));
    });

    test('menormalkan huruf, tanda baca, dan sinonim hp', () {
      final targetHp = _barang(
        id: 'hp-lost',
        jenis: JenisLaporan.hilang,
        nama: 'HP Samsung',
        deskripsi: 'HP warna hitam, ada casing bening',
        pemilikEmail: 'pemilik@student.uin-malang.ac.id',
      );
      final foundHp = _barang(
        id: 'hp-found',
        jenis: JenisLaporan.ditemukan,
        nama: 'Handphone Samsung!',
        deskripsi: 'Handphone hitam dengan casing bening.',
        tanggal: DateTime(2026, 10, 20, 11),
        pemilikEmail: 'penemu@student.uin-malang.ac.id',
      );

      final matches = service.findMatches(
        target: targetHp,
        candidates: [foundHp],
      );

      expect(matches, hasLength(1));
      expect(matches.single.report.id, 'hp-found');
      expect(matches.single.reasons, contains('Nama barang mirip'));
    });
  });

  testWidgets('detail menampilkan kandidat dan meneruskan ketukan',
      (tester) async {
    final candidate = _barang(
      id: 'found-ui',
      jenis: JenisLaporan.ditemukan,
      nama: 'Kunci motor Honda',
      tanggal: DateTime(2026, 10, 20, 10),
      pemilikEmail: 'penemu@student.uin-malang.ac.id',
    );
    BarangItem? tapped;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: DetailBarangScreen(
          item: target,
          currentUserEmail: 'pemilik@student.uin-malang.ac.id',
          onKlaim: () {},
          kandidat: [
            ReportMatch(
              report: candidate,
              score: .87,
              reasons: const ['Nama barang mirip', 'Lokasi berdekatan'],
            ),
          ],
          onKandidatTap: (item) => tapped = item,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('87% cocok'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Kandidat cocok'), findsOneWidget);
    expect(find.text('87% cocok'), findsOneWidget);
    expect(find.text('Nama barang mirip'), findsOneWidget);

    await tester.tap(find.text('87% cocok'));
    await tester.pump();

    expect(tapped?.id, 'found-ui');
  });
}
