# Lifecycle-Aware Upload Queue TEMU

- Tanggal implementasi: 26 Oktober 2026
- Status: fondasi foreground selesai, belum memakai background worker OS.

## 1. Tujuan

Membuat upload laporan tidak bergantung pada satu kesempatan request. Jika
jaringan atau server sedang bermasalah, laporan disimpan di antrean lokal dan
dicoba lagi saat aplikasi aktif kembali.

## 2. Komponen

| Komponen | Fungsi |
|---|---|
| `ReportUploadQueue` | Mengatur submit langsung, antrean, retry, dan backoff |
| `PendingUpload` | Model item antrean yang disimpan ke Hive |
| `ApiException` | Membawa status HTTP agar error validasi tidak diulang terus |
| `temu_upload_queue` | Box Hive baru untuk antrean upload |
| `JelajahScreen.pendingUploadCount` | Banner jumlah laporan yang menunggu koneksi |

## 3. Alur submit

1. Pengguna menekan **TERBITKAN LAPORAN**.
2. `ReportUploadQueue.submit` mencoba upload langsung ke API.
3. Jika berhasil:
   - laporan disimpan ke cache lokal;
   - form dikosongkan;
   - pesan sukses ditampilkan;
   - laporan langsung masuk daftar UI.
4. Jika gagal karena jaringan, timeout, atau server 5xx/408/429:
   - laporan disimpan ke `temu_upload_queue`;
   - form dikosongkan;
   - pesan “disimpan dan akan dikirim otomatis” ditampilkan;
   - banner antrean muncul di halaman Jelajah.
5. Jika gagal karena validasi/otorisasi 4xx:
   - laporan tidak masuk antrean;
   - form tetap terisi;
   - pesan error ditampilkan.

## 4. Lifecycle dan retry

Antrean diproses:

- saat `MainNavigationScreen` pertama kali dibuka;
- saat aplikasi kembali ke `resumed`;
- setiap siklus sinkronisasi 5 detik;
- saat pengguna membuka kembali aplikasi setelah proses sebelumnya terhenti.

Saat aplikasi `paused`/`hidden`, timer dihentikan dan antrean tetap tersimpan di
Hive. Tidak ada upload yang dimulai saat aplikasi berada di background.

Backoff retry:

| Percobaan gagal | Jeda berikutnya |
|---|---|
| 1 | 5 detik |
| 2 | 15 detik |
| 3 | 60 detik |
| 4+ | 300 detik |

Jika satu item gagal karena koneksi, putaran retry dihentikan agar tidak
menghantam server. Item berikutnya dicoba pada siklus berikutnya.

## 5. Idempotensi

- ID laporan dibuat sekali saat submit pertama dan dipakai ulang jika pengguna
  menekan submit lagi setelah gagal.
- Endpoint `POST sync` hanya memperbarui laporan jika `user_email` sama dengan
  pemilik request.
- Dengan demikian, retry setelah timeout tidak membuat laporan ganda dan tidak
  bisa menimpa laporan akun lain.
- Antrean difilter berdasarkan email akun aktif, sehingga akun lain tidak
  memproses atau melihat jumlah antrean pengguna sebelumnya.

## 6. Batasan saat ini

- Retry hanya berjalan saat aplikasi foreground/aktif. Belum memakai WorkManager
  atau background isolate OS.
- Belum ada listener konektivitas khusus; retry mengandalkan timer lifecycle.
- Item yang gagal permanen (4xx) dihapus dari antrean dan dicatat di log, belum
  ditampilkan sebagai daftar gagal permanen.
- Belum ada halaman khusus untuk melihat detail isi antrean.
- State recovery sudah tersedia untuk sesi, draft laporan, dan cold-start cache;
  detailnya ada di `docs/STATE_RECOVERY.md`.
- Candidate matching belum termasuk dalam tahap ini.

## 7. Verifikasi

- `flutter analyze` bersih.
- `flutter test` mencakup:
  - submit langsung berhasil;
  - submit gagal jaringan masuk antrean;
  - error validasi tidak masuk antrean;
  - flush item jatuh tempo;
  - item belum jatuh tempo dilewati;
  - `force` untuk retry manual;
  - backoff dan kenaikan `attempts`;
  - pembersihan item gagal permanen;
  - filter antrean berdasarkan email akun;
  - serialisasi `PendingUpload`.
- Uji backend live:
  - API lokal sehat pada MySQL port 3307;
  - insert laporan oleh akun A berhasil;
  - akun B tidak dapat menimpa laporan A;
  - akun A tetap dapat memperbarui laporannya sendiri;
  - data uji dibersihkan setelah pengujian.

## 8. Langkah berikutnya

1. Uji lifecycle nyata di emulator/perangkat: pause, resume, matikan proses.
2. ~~State recovery: draft laporan dan pemulihan sesi.~~ Selesai; lihat
   `docs/STATE_RECOVERY.md`.
3. Candidate matching hilang/temuan dengan skor dan evaluasi.
4. Opsi background worker bila diperlukan untuk klaim judul yang lebih kuat.
