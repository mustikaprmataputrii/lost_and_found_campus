part of '../../main.dart';

class MockDataRepository {
  static List<BarangItem> initialBarang() => [
        BarangItem(
          id: '1',
          nama: 'Kunci Motor Vario',
          lokasi: 'Saintek Lt. 3',
          deskripsi:
              'Ditemukan dekat Lab Komputer 2, gantungannya memakai pita hijau.',
          jenis: JenisLaporan.ditemukan,
          pelapor: 'Ahmad Abdullah',
          kontak: '08123456789',
          tanggal: DateTime(2026, 9, 6, 16, 10),
        ),
        BarangItem(
          id: '2',
          nama: 'KTM an. Indah Permata',
          lokasi: 'Perpustakaan Pusat',
          deskripsi: 'Tertinggal di meja baca lantai 1 area tenang.',
          jenis: JenisLaporan.ditemukan,
          pelapor: 'Siti Aminah',
          kontak: '08987654321',
          tanggal: DateTime(2026, 9, 6, 13, 10),
        ),
        BarangItem(
          id: '3',
          nama: 'Jas Almamater UIN',
          lokasi: 'Masjid Ulul Albab',
          deskripsi: 'Jas almamater ukuran L tertinggal di area tempat wudhu.',
          jenis: JenisLaporan.hilang,
          pelapor: 'Rian Farhan',
          kontak: '085512344321',
          tanggal: DateTime(2026, 9, 5, 16, 10),
        ),
      ];

  static List<SesiChat> initialChats(List<BarangItem> barang) => [
        SesiChat(
          id: 'chat_1',
          barang: barang.first,
          isOnline: true,
          unreadCount: 2,
          pesanList: [
            PesanChat(
              pengirim: 'Ahmad Abdullah',
              teks: 'Assalamu\'alaikum, apakah benar kunci motor Anda?',
              waktu: DateTime.now().subtract(const Duration(minutes: 20)),
              isMe: false,
            ),
            PesanChat(
              pengirim: 'Ahmad Abdullah',
              teks: 'Bisa ditemui di Gedung Saintek sekarang, ya.',
              waktu: DateTime.now().subtract(const Duration(minutes: 5)),
              isMe: false,
            ),
          ],
        ),
      ];

  static List<NotifikasiItem> initialNotifications() => [
        NotifikasiItem(
          title: 'Pesan baru',
          message: 'Ahmad mengirim 2 pesan tentang Kunci Motor Vario.',
          waktu: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        NotifikasiItem(
          title: 'Laporan populer',
          message: 'Ada laporan baru di sekitar Perpustakaan Pusat.',
          waktu: DateTime.now().subtract(const Duration(hours: 1)),
          isRead: true,
        ),
      ];
}
