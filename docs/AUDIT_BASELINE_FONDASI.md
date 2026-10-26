# Audit Baseline dan Perbaikan Fondasi TEMU

- Tanggal audit: 26 Oktober 2026
- Project: `lost_and_found_campus`
- Commit baseline: `df45066` (`Add mutual claims and message unsend`)
- Flutter: 3.47.1 / Dart 3.13.1
- Backend: PHP + MySQL/MariaDB (Laragon)

## 1. Tujuan

Audit ini dilakukan sebelum menambahkan fitur judul jurnal. Fokusnya adalah
memastikan fondasi upload, penyimpanan, dan sinkronisasi cukup aman sehingga
fitur baru tidak dibangun di atas perilaku yang menyembunyikan kegagalan.

Prinsip perubahan:

- tidak melakukan rewrite;
- tidak menghapus fitur yang sudah berjalan;
- perubahan bersifat aditif atau perbaikan terarah;
- perilaku lama yang masih valid dipertahankan;
- setiap perubahan diverifikasi dengan analyzer dan test.

## 2. Baseline yang sudah diverifikasi

| Pemeriksaan | Hasil |
|---|---|
| `flutter analyze --no-pub` | Tidak ada issue |
| `flutter test --no-pub` | 31 test lulus (13 test lama + 18 test fondasi/queue) |
| `php -l backend/public/api/index.php` | Tidak ada syntax error |
| APK di `Downloads` | ±52 MB, package `com.example.lost_and_found_campus`, label `lost_and_found_campus`, versi 1.0.0 |
| Isi APK | API mengarah ke dev tunnel HTTPS; release masih memakai debug signing |

Catatan: APK belum diuji ulang di perangkat fisik. Pengujian end-to-end backend
live sudah dijalankan memakai instance MySQL Laragon pada port 3307 dan API
lokal `127.0.0.1:8088`. Hasilnya: health check berhasil, laporan akun A dapat
dibuat dan diperbarui, akun B tidak dapat menimpa laporan akun A, dan seluruh
data uji sudah dibersihkan.

## 3. Temuan utama

| ID | Tingkat | Temuan | Bukti | Dampak |
|---|---|---|---|---|
| F-01 | Tinggi | Upload laporan bersifat fire-and-forget | `LaporBarangScreen._simpanLaporan` memanggil callback lalu langsung membersihkan form; `MainNavigationScreen._tambahBarang` memakai `unawaited(_simpanData())` | Form terlihat berhasil meskipun server gagal menerima laporan |
| F-02 | Tinggi | Error API ditelan di repository | `AppDataRepository.saveAll` menangkap semua error remote tanpa meneruskannya | UI tidak punya cara membedakan sukses dan gagal |
| F-03 | Sedang | Cache lokal tidak dipakai saat API gagal | `AppDataRepository.load` melakukan `rethrow`; `LocalDataRepository.load` tidak pernah dipanggil dari repository utama | Data yang sudah ada tidak bisa menjadi fallback saat offline |
| F-04 | Tinggi | `POST sync` dapat menimpa laporan milik akun lain | `INSERT ... ON DUPLICATE KEY UPDATE` memperbarui kolom laporan berdasarkan `id` tanpa memeriksa `user_email` | Klien yang mengetahui ID laporan dapat mengubah isi laporan akun lain |
| F-05 | Sedang | Konfigurasi APK belum siap distribusi | package `com.example`, label masih nama package, release memakai debug signing, API memakai dev tunnel | APK hanya cocok untuk demo/internal, belum untuk rilis resmi |
| F-06 | Sedang | Test belum mencakup fondasi upload/offline | Test yang ada berfokus pada login, form, chat, dan klaim | Regresi pada error handling dan cache tidak terdeteksi |
| F-07 | Sebagian | Fitur judul jurnal belum lengkap | Lifecycle-aware upload queue sudah ditambahkan; state recovery dan candidate matching belum | Dua fitur judul masih menjadi pekerjaan tahap berikutnya |
| F-08 | Sedang | Error hapus laporan dan tandai notifikasi tidak tertangani | `DetailBarangScreen._konfirmasiHapus` memanggil `onDelete` tanpa `try/catch`; `_bukaNotifikasi` memakai `unawaited` pada API | Berpotensi menjadi unhandled asynchronous error saat server offline |

## 4. Ruang lingkup patch fondasi

Patch ini menangani F-01 sampai F-04, F-07 (sebagian), dan F-08, ditambah test
untuk F-06.

### 4.1 Upload laporan

- Callback pembuatan laporan mengembalikan `ReportSubmissionResult`
  (`uploaded` atau `queued`).
- Form menampilkan status mengirim dan tidak dapat diklik ganda.
- Jika server menerima laporan, form dikosongkan dan laporan masuk daftar UI.
- Jika gagal sementara (jaringan/timeout/5xx), laporan disimpan ke antrean
  lokal, form dikosongkan, dan banner antrean ditampilkan.
- Jika gagal permanen (validasi/otorisasi 4xx), isi form dipertahankan dan
  pesan error ditampilkan.
- Laporan baru disimpan terlebih dahulu ke server atau ke antrean lokal, baru
  dianggap diterima oleh UI.

### 4.2 Propagasi error

- `AppDataRepository.saveAll` tidak lagi menelan error remote.
- Penyimpanan cache tetap best-effort agar kegagalan cache tidak menghalangi upload.
- Proses latar belakang tetap menangani error secara eksplisit agar tidak menjadi
  unhandled asynchronous error.
- Kegagalan hapus laporan ditampilkan ke pengguna dan tidak menutup halaman
  detail.
- Kegagalan menandai notifikasi dibaca dicatat tanpa menghentikan UI.

### 4.3 Fallback cache

- `LocalDataRepository.load` mendapat opsi `seedIfEmpty`.
- `AppDataRepository.load` mencoba server terlebih dahulu.
- Jika server gagal dan cache memiliki data, cache dikembalikan dengan penanda
  `fromCache = true`.
- Jika cache kosong, error asli dari server tetap diteruskan.

### 4.4 Otorisasi sinkronisasi laporan

- Update laporan di `POST sync` dibuat kondisional.
- Baris hanya boleh diperbarui jika `user_email` yang tersimpan sama dengan
  email pemilik request.
- Laporan lama tanpa pemilik tidak otomatis diklaim oleh pengirim snapshot.

### 4.5 Lifecycle-aware upload queue

- Antrean disimpan di box Hive `temu_upload_queue` dan tetap ada setelah
  aplikasi ditutup.
- Upload dicoba saat submit, saat aplikasi dibuka, saat kembali ke `resumed`,
  dan pada siklus sinkronisasi 5 detik.
- Retry memakai backoff 5/15/60/300 detik.
- Antrean difilter berdasarkan email akun aktif.
- Error 4xx yang tidak dapat dipulihkan tidak diulang terus.
- Detail desain dan batasan ada di `docs/LIFECYCLE_UPLOAD_QUEUE.md`.

## 5. Yang tidak diubah pada patch ini

- Struktur navigasi dan desain UI utama.
- Skema database.
- Konfigurasi signing, package ID, dan URL API APK.
- Mekanisme login/auto-login.
- State recovery dan candidate matching.
- Endpoint chat, klaim, dan notifikasi yang sudah berjalan.

## 6. Kriteria penerimaan

1. `flutter analyze` tetap bersih.
2. Seluruh test lama tetap lulus.
3. Ada test baru untuk:
   - error remote yang diteruskan setelah cache disimpan;
   - fallback cache saat API gagal;
   - error asli saat API gagal dan cache kosong;
   - form laporan yang tidak hilang saat upload gagal permanen;
   - form laporan yang dikosongkan setelah masuk antrean;
   - submit, retry, backoff, filter email, dan pembersihan antrean;
   - halaman detail yang tetap terbuka saat hapus laporan gagal.
4. `php -l backend/public/api/index.php` lulus.
5. Uji backend live untuk otorisasi `POST sync` lulus.
6. Tidak ada perubahan pada file yang belum terkait.

## 7. Status perubahan dan rollback

Perubahan berada pada branch `feat/foundation-upload-queue` dan belum di-push ke
GitHub saat dokumen ini diperbarui. Rollback dapat dilakukan dengan
mengembalikan file yang berubah melalui `git diff`/`git checkout -- <file>` atau
kembali ke commit `df45066`. Konfigurasi demo pribadi
`scripts/demo.local.ps1` diabaikan Git; template aman tersedia di
`scripts/demo.local.example.ps1`.

## 8. Rencana setelah fondasi

1. ~~Lifecycle-aware upload queue dan retry.~~ Selesai untuk mode foreground.
2. Pengujian skenario offline/foreground-background pada perangkat/emulator.
3. State recovery: draft, sesi, dan cold-start cache.
4. Candidate matching hilang/temuan dengan skor dan evaluasi.
5. Penyiapan APK uji dan dokumentasi jurnal.
