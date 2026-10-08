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
            onLaporanDibuat: (_) {},
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
            onLaporanDibuat: (laporan) => laporanTerkirim = laporan,
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

    testWidgets('pilihan sumber foto menampilkan kamera dan galeri',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LaporBarangScreen(
            defaultNama: 'Mahasiswa Uji',
            onLaporanDibuat: (_) {},
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
  });
}
