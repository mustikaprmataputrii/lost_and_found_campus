import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_campus/main.dart';

BarangItem _barangUji() => BarangItem(
      id: 'test-barang',
      nama: 'Kunci motor uji',
      lokasi: 'Perpustakaan UIN',
      deskripsi: 'Kunci dengan gantungan biru.',
      jenis: JenisLaporan.hilang,
      pelapor: 'Mahasiswa Uji',
      kontak: '081234567890',
      tanggal: DateTime(2026, 10, 7, 10),
      pemilikEmail: 'owner@student.uin-malang.ac.id',
    );

SesiChat _sesiUji() => SesiChat(
      id: 'test-chat',
      barang: _barangUji(),
      pesanList: [
        PesanChat(
          pengirim: 'Mahasiswa Uji',
          teks: 'Apakah kunci ini sudah ditemukan?',
          waktu: DateTime(2026, 10, 7, 10, 15),
          isMe: false,
        ),
      ],
      isOnline: true,
      unreadCount: 2,
    );

void main() {
  group('Pembuatan laporan', () {
    testWidgets('form laporan memvalidasi seluruh input wajib', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LaporBarangScreen(
            defaultNama: 'Mahasiswa Uji',
            onLaporanDibuat: (_) async =>
                const ReportSubmissionResult.uploaded(),
          ),
        ),
      );

      final submitButton = find.text('TERBITKAN LAPORAN');
      await tester.scrollUntilVisible(
        submitButton,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text('Bagian ini wajib diisi'), findsNWidgets(4));
    });

    testWidgets('form laporan meneruskan data laporan yang valid',
        (tester) async {
      BarangItem? laporanTerkirim;

      await tester.pumpWidget(
        MaterialApp(
          home: LaporBarangScreen(
            defaultNama: 'Mahasiswa Uji',
            onLaporanDibuat: (laporan) async {
              laporanTerkirim = laporan;
              return const ReportSubmissionResult.uploaded();
            },
          ),
        ),
      );

      Future<void> fillField(String label, String value) async {
        final labelFinder = find.text(label);
        await tester.scrollUntilVisible(
          labelFinder,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        final field = find
            .ancestor(of: labelFinder, matching: find.byType(TextFormField))
            .first;
        await tester.enterText(field, value);
      }

      await fillField('Nama barang', 'Dompet hitam');
      await fillField('Lokasi di kampus', 'Gedung Rektorat');
      await fillField(
          'Ciri-ciri dan detail', 'Ada kartu mahasiswa di dalamnya');
      await fillField('Nomor WhatsApp aktif', '081234567890');

      final submitButton = find.text('TERBITKAN LAPORAN');
      await tester.scrollUntilVisible(
        submitButton,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submitButton);
      await tester.pump();

      expect(laporanTerkirim, isNotNull);
      expect(laporanTerkirim!.nama, 'Dompet hitam');
      expect(laporanTerkirim!.lokasi, 'Gedung Rektorat');
      expect(laporanTerkirim!.pelapor, 'Mahasiswa Uji');
      expect(find.text('Laporan berhasil diterbitkan ke warga kampus.'),
          findsOneWidget);
    });

    testWidgets('form laporan mengosongkan isi saat masuk antrean',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LaporBarangScreen(
            defaultNama: 'Mahasiswa Uji',
            onLaporanDibuat: (_) async => const ReportSubmissionResult.queued(),
          ),
        ),
      );

      Future<void> fillField(String label, String value) async {
        final labelFinder = find.text(label);
        await tester.scrollUntilVisible(
          labelFinder,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        final field = find
            .ancestor(of: labelFinder, matching: find.byType(TextFormField))
            .first;
        await tester.enterText(field, value);
      }

      await fillField('Nama barang', 'Dompet hitam');
      await fillField('Lokasi di kampus', 'Gedung Rektorat');
      await fillField(
          'Ciri-ciri dan detail', 'Ada kartu mahasiswa di dalamnya');
      await fillField('Nomor WhatsApp aktif', '081234567890');

      final submitButton = find.text('TERBITKAN LAPORAN');
      await tester.scrollUntilVisible(
        submitButton,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(
          find.text(
              'Laporan disimpan dan akan dikirim otomatis saat koneksi tersedia.'),
          findsOneWidget);
      final fields =
          tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(fields[0].controller?.text, isEmpty);
      expect(fields[1].controller?.text, isEmpty);
      expect(find.text('TERBITKAN LAPORAN'), findsOneWidget);
    });

    testWidgets('form laporan mempertahankan isi saat upload gagal',
        (tester) async {
      final submittedIds = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: LaporBarangScreen(
            defaultNama: 'Mahasiswa Uji',
            onLaporanDibuat: (laporan) async {
              submittedIds.add(laporan.id);
              throw Exception('Server offline');
            },
          ),
        ),
      );

      Future<void> fillField(String label, String value) async {
        final labelFinder = find.text(label);
        await tester.scrollUntilVisible(
          labelFinder,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        final field = find
            .ancestor(of: labelFinder, matching: find.byType(TextFormField))
            .first;
        await tester.enterText(field, value);
      }

      await fillField('Nama barang', 'Dompet hitam');
      await fillField('Lokasi di kampus', 'Gedung Rektorat');
      await fillField(
          'Ciri-ciri dan detail', 'Ada kartu mahasiswa di dalamnya');
      await fillField('Nomor WhatsApp aktif', '081234567890');

      final submitButton = find.text('TERBITKAN LAPORAN');
      await tester.scrollUntilVisible(
        submitButton,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(
          find.text('Laporan gagal dikirim. Server offline'), findsOneWidget);
      final fields =
          tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(fields[0].controller?.text, 'Dompet hitam');
      expect(fields[1].controller?.text, 'Gedung Rektorat');
      expect(find.text('TERBITKAN LAPORAN'), findsOneWidget);

      // Tunggu SnackBar error hilang agar tombol tidak terhalang overlay.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(find.text('TERBITKAN LAPORAN'));
      await tester.pumpAndSettle();

      expect(submittedIds, hasLength(2));
      expect(submittedIds[0], submittedIds[1]);
    });

    testWidgets('detail tetap terbuka saat hapus laporan gagal',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DetailBarangScreen(
            item: _barangUji(),
            currentUserEmail: 'owner@student.uin-malang.ac.id',
            onKlaim: () {},
            onDelete: () async {
              throw Exception('Server offline');
            },
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Detail laporan'), findsOneWidget);
      expect(
          find.text('Laporan gagal dihapus. Server offline'), findsOneWidget);
    });

    testWidgets('pilihan sumber foto menampilkan kamera dan galeri',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LaporBarangScreen(
            defaultNama: 'Mahasiswa Uji',
            onLaporanDibuat: (_) async =>
                const ReportSubmissionResult.uploaded(),
          ),
        ),
      );

      await tester.tap(find.text('Tambahkan foto barang').first);
      await tester.pumpAndSettle();

      expect(find.text('Tambahkan foto barang'), findsNWidgets(2));
      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Galeri'), findsOneWidget);
    });
  });

  group('Chat dan navigasi chat', () {
    testWidgets('daftar chat menampilkan badge unread dan status online',
        (tester) async {
      final sesi = _sesiUji();
      var selected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DaftarChatScreen(
            daftarSesi: [sesi],
            onSesiTap: (_) => selected = true,
          ),
        ),
      );

      expect(find.text('Kunci motor uji'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);

      await tester.tap(find.text('Kunci motor uji'));
      expect(selected, isTrue);
    });

    testWidgets('pengguna dapat mengirim pesan di room chat', (tester) async {
      final sesi = _sesiUji();
      var changed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: RoomChatScreen(
            sesi: sesi,
            currentUserName: 'Saya',
            currentUserEmail: '23123456@student.uin-malang.ac.id',
            onStatusChanged: () => changed = true,
          ),
        ),
      );

      expect(find.text('Apakah kunci ini sudah ditemukan?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Sudah saya temukan.');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.text('Sudah saya temukan.'), findsOneWidget);
      expect(sesi.pesanList.last.teks, 'Sudah saya temukan.');
      expect(changed, isTrue);
    });

    testWidgets('pengirim dapat membatalkan pesan terkirim untuk kedua pihak',
        (tester) async {
      final message = PesanChat(
        id: '42',
        pengirim: 'Saya',
        pengirimEmail: '23123456@student.uin-malang.ac.id',
        teks: 'Pesan yang dibatalkan',
        waktu: DateTime(2026, 10, 7, 10, 20),
        isMe: true,
      );
      final sesi = SesiChat(
        id: 'test-chat',
        barang: _barangUji(),
        pesanList: [message],
      );
      String? deletedId;

      await tester.pumpWidget(MaterialApp(
        home: RoomChatScreen(
          sesi: sesi,
          currentUserName: 'Saya',
          currentUserEmail: '23123456@student.uin-malang.ac.id',
          onStatusChanged: () {},
          onDeleteMessage: (id) async {
            deletedId = id;
            sesi.pesanList.removeWhere((item) => item.id == id);
            return sesi;
          },
        ),
      ));

      await tester.longPress(find.text('Pesan yang dibatalkan'));
      await tester.pumpAndSettle();
      expect(find.text('Batalkan pengiriman pesan?'), findsOneWidget);
      await tester.tap(find.text('Batalkan pesan'));
      await tester.pumpAndSettle();

      expect(deletedId, '42');
      expect(find.text('Pesan yang dibatalkan'), findsNothing);
      expect(find.text('Pesan berhasil dibatalkan untuk kedua pihak.'),
          findsOneWidget);
    });

    testWidgets('klaim menunggu persetujuan pemilik laporan', (tester) async {
      final sesi = _sesiUji();
      var requested = false;
      await tester.pumpWidget(MaterialApp(
        home: RoomChatScreen(
          sesi: sesi,
          currentUserName: 'Pengklaim',
          currentUserEmail: '23123456@student.uin-malang.ac.id',
          onStatusChanged: () {},
          onRequestClaim: () async {
            requested = true;
            sesi.barang
              ..status = StatusBarang.prosesKlaim
              ..claimantEmail = '23123456@student.uin-malang.ac.id';
            return sesi;
          },
        ),
      ));

      await tester.tap(find.text('Ajukan klaim'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajukan klaim').last);
      await tester.pumpAndSettle();

      expect(requested, isTrue);
      expect(
          find.text('Menunggu persetujuan pemilik laporan.'), findsOneWidget);
    });

    testWidgets('pemilik menyetujui klaim dan laporan menjadi selesai',
        (tester) async {
      final sesi = _sesiUji();
      sesi.barang
        ..status = StatusBarang.prosesKlaim
        ..claimantEmail = '23123456@student.uin-malang.ac.id';
      var approved = false;

      await tester.pumpWidget(MaterialApp(
        home: RoomChatScreen(
          sesi: sesi,
          currentUserName: 'Pemilik',
          currentUserEmail: 'owner@student.uin-malang.ac.id',
          onStatusChanged: () {},
          onRespondToClaim: ({required approve}) async {
            approved = approve;
            sesi.barang.status = StatusBarang.selesai;
            return sesi;
          },
        ),
      ));

      await tester.tap(find.text('Setujui klaim'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setujui').last);
      await tester.pumpAndSettle();

      expect(approved, isTrue);
      expect(sesi.barang.status, StatusBarang.selesai);
      expect(find.text('Klaim disetujui kedua pihak.'), findsOneWidget);
    });
  });
}
