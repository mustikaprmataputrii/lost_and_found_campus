# Pemulihan State Aplikasi TEMU

Dokumen ini mencatat implementasi state recovery pada aplikasi TEMU UIN Malang.
Fokus tahap ini adalah pemulihan sesi login, draft laporan, dan snapshot cache
saat aplikasi dibuka kembali. Candidate matching diimplementasikan pada tahap
lanjutan dan didokumentasikan di `docs/CANDIDATE_MATCHING.md`.

## Tujuan

1. Pengguna tidak perlu login ulang setiap kali aplikasi dibuka.
2. Isi laporan yang belum selesai tidak hilang saat aplikasi ditutup atau
   dihentikan sistem.
3. Data terakhir tetap terlihat saat cold start, lalu diperbarui dari server.
4. Snapshot cache tidak ditampilkan kepada akun yang berbeda.

## Komponen

| Komponen | Tanggung jawab |
|---|---|
| `AuthService` | Menyimpan dan membaca sesi mahasiswa/admin dari `SharedPreferences`. |
| `AuthGateScreen` | Menentukan halaman awal: splash, login, dashboard mahasiswa, atau dashboard admin. |
| `ReportDraftService` | Menyimpan draft laporan per email ke Hive. |
| `LaporBarangScreen` | Memulihkan, menyimpan otomatis, dan menghapus draft. |
| `AppDataRepository.loadCache` | Mengambil snapshot Hive hanya jika penanda pemilik email cocok. |
| `MainNavigationScreen` | Menampilkan cache awal, lalu menyinkronkan data server. |

## Alur startup

```text
main()
  -> LocalDataRepository.initialize()
  -> AuthGateScreen
       -> AuthService.loadSession()
            -> sesi tidak ada        : LoginScreen
            -> sesi mahasiswa        : DashboardScreen
            -> sesi admin + token    : AdminDashboardScreen
            -> error                 : LoginScreen
```

Setelah pengguna masuk ke ruang utama, `MainNavigationScreen` menjalankan dua
alur paralel:

1. `_pulihkanCacheLokal()` membaca snapshot Hive dan langsung menampilkannya.
2. `_siapkanDataAwal()` memproses antrean upload, lalu memuat data server.

Jika server berhasil dimuat lebih dulu, hasil cache yang terlambat tidak boleh
menimpa data server. Penanda `_serverLoadSelesai` mencegah urutan tersebut.

## Penyimpanan

### Sesi login

`SharedPreferences` menyimpan:

- `user_email`
- `user_nim`
- `user_nama`
- `user_role` (`mahasiswa` atau `admin`)
- `admin_token` hanya untuk admin

`AuthService.clear()` menghapus kunci autentikasi dan `waktu_sesi_uin`, tetapi
tidak memakai `prefs.clear()`. Dengan begitu preferensi lain tetap aman.

Pemulihan sesi adalah pemulihan identitas lokal. Login mahasiswa pertama tetap
divalidasi backend; token admin tetap dapat ditolak server jika sudah kedaluwarsa.

### Draft laporan

Draft disimpan di box Hive `temu_report_drafts` dengan email sebagai key.
Isi draft:

- nama barang
- lokasi
- deskripsi/ciri-ciri
- nomor WhatsApp
- jenis laporan
- foto (base64)
- waktu pembaruan

Perubahan form dijadwalkan sekitar 450 ms setelah input terakhir. Draft dihapus
saat pengguna menekan tombol laporan dan laporan berhasil dikirim atau masuk
antrean, atau saat pengguna menekan **Hapus draft**.

Jika pengguna mulai mengetik sebelum proses pemulihan draft selesai, input baru
dipertahankan dan draft lama tidak menimpa form.

### Cache data

Box Hive yang digunakan:

- `temu_reports`
- `temu_chats`
- `temu_notifications`
- `temu_upload_queue`
- `temu_report_drafts`
- `temu_cache_meta` (penanda `owner_email`)

Penanda pemilik cache diperbarui setiap kali snapshot server berhasil disimpan.
Saat API gagal atau cold start, cache hanya dipakai jika penanda tersebut cocok
dengan email akun aktif. Ini mencegah chat/notifikasi akun lain tampil setelah
pergantian akun di perangkat yang sama.

## Perilaku UI

- Layar splash menampilkan “Memulihkan sesi...” selama sesi dibaca.
- Form laporan yang berhasil dipulihkan menampilkan banner
  “Draft laporan dipulihkan. Periksa kembali sebelum diterbitkan.”
- Halaman Jelajah menampilkan banner data tersimpan saat snapshot berasal dari
  cache atau saat sinkronisasi server belum berhasil.

## Pengujian

Test otomatis terkait state recovery berada di:

- `test/state_recovery_test.dart`
  - simpan/pulihkan sesi mahasiswa
  - sesi admin memerlukan token
  - `clear()` tidak menghapus preferensi lain
  - `AuthGateScreen` memilih dashboard atau login
  - draft mengisi kembali form
  - perubahan form tersimpan otomatis
  - draft dihapus setelah laporan terkirim
  - tombol hapus draft membersihkan form dan penyimpanan
- `test/foundation_test.dart`
  - cache akun lain tidak dipakai
  - `loadCache` menolak cache milik akun lain

Saat state recovery selesai, total test repository adalah **42**. Setelah
candidate matching ditambahkan, totalnya menjadi **48** dan semuanya lulus.
`flutter analyze` juga lulus.

## Batasan

- Sesi mahasiswa belum memakai token server dengan masa berlaku.
- Draft hanya tersimpan di perangkat dan belum disinkronkan ke server.
- Cold-start cache menampilkan snapshot terakhir; perubahan dari perangkat lain
  baru terlihat setelah sinkronisasi berhasil.
- Jika API dan cache sama-sama tidak tersedia, aplikasi tetap menampilkan error
  agar pengguna tidak menerima status berhasil palsu.

## Langkah berikutnya

1. Penyimpanan draft ke server atau mekanisme ekspor draft.
2. Kalibrasi candidate matching dengan dataset laporan nyata.
3. Build APK final dan pengujian perangkat.
