# TEMU UIN Malang

Aplikasi Lost & Found kampus untuk membantu mahasiswa UIN Maulana Malik Ibrahim Malang melaporkan, mencari, dan mengklaim barang hilang atau ditemukan.

Project ini dibuat menggunakan Flutter dan memiliki backend REST API berbasis PHP + MySQL/MariaDB yang dapat dijalankan melalui Laragon.

## Fitur utama

- Login hanya menggunakan email resmi mahasiswa dengan format:
  `NIM@student.uin-malang.ac.id`
- Satu email dikunci ke satu NIM dan satu nama yang sudah terdaftar.
- Laporan, chat, dan notifikasi tersinkron lintas akun melalui backend bersama.
- Login admin terpisah dengan dashboard untuk melihat seluruh laporan, chat, dan notifikasi.
- Dashboard ringkasan aplikasi.
- Jelajah laporan barang hilang dan ditemukan.
- Pencarian berdasarkan nama/deskripsi barang.
- Filter jenis laporan dan lokasi.
- Pembuatan laporan barang.
- Upload foto langsung dari kamera atau galeri.
- Detail barang dan pembukaan sesi chat klaim.
- Chat dengan status online/last seen.
- Popup notifikasi pesan masuk.
- Badge jumlah pesan dan pemberitahuan.
- Penandaan barang sebagai selesai diklaim.
- Profil pengguna dan penghitung waktu sesi aplikasi.
- Logo dan nuansa visual UIN Malang.
- Penyimpanan utama menggunakan MySQL/MariaDB melalui REST API.
- Cache lokal menggunakan Hive sebagai buffer penulisan perangkat, sedangkan server menjadi sumber data bersama.
- Antrean upload lokal dengan retry dan backoff saat jaringan atau server bermasalah.
- Fallback cache Hive saat API sementara tidak dapat diakses.
- Sinkronisasi berkala memperbarui laporan, chat, notifikasi, dan status kehadiran pengguna.
- Dukungan target Flutter Web, Android, iOS, Windows, macOS, dan Linux sesuai ketersediaan toolchain perangkat.

## Arsitektur aplikasi

```text
Flutter UI
   |
   +-- AppDataRepository
   |      |
   |      +-- ApiService
   |      |      |
   |      |      +-- PHP REST API
   |      |             |
   |      |             +-- MySQL/MariaDB Laragon
   |      |
   |      +-- LocalDataRepository
   |             |
   |             +-- Hive cache/fallback
   |
   +-- ReportUploadQueue
          |
          +-- ApiService
          +-- Hive outbox (retry)
```

Aplikasi mengambil data bersama dari backend MySQL melalui REST API. Cache Hive
dipakai sebagai buffer penulisan perangkat dan fallback saat backend gagal
diakses. Laporan yang gagal dikirim karena masalah jaringan disimpan di outbox
Hive, lalu dicoba ulang saat aplikasi aktif kembali. Cache tidak digunakan untuk
menampilkan data akun lain; antrean juga difilter berdasarkan email akun aktif.

## Struktur folder penting

```text
lib/
├── core/
│   ├── theme/                 # Tema dan warna UIN
│   └── utils/                 # Formatter tanggal dan waktu
├── models/                    # Model laporan, chat, pesan, notifikasi
├── repositories/
│   ├── app_data_repository.dart
│   ├── local_data_repository.dart
│   └── mock_data_repository.dart
├── screens/                   # Halaman login, dashboard, laporan, chat, profil
├── services/
│   ├── api_service.dart       # Komunikasi Flutter dengan REST API
│   ├── app_services.dart      # Auth dan session service
│   └── report_upload_queue.dart # Antrean upload, retry, dan backoff
├── widgets/                   # Komponen UI yang digunakan bersama
└── main.dart                  # Entry point dan registrasi modul

backend/
├── database/schema.sql        # Struktur database MySQL
├── public/api/index.php       # REST API PHP
├── config.php                 # Konfigurasi koneksi database
└── README.md                  # Panduan backend

docs/                          # Audit, panduan queue, dan laporan tahap
scripts/                       # Script demo lokal dan template konfigurasi
test/                          # Unit dan widget test
```

## Kebutuhan sistem

- Flutter SDK dan Dart SDK.
- PHP 8.3 atau kompatibel.
- Laragon dengan MySQL/MariaDB.
- Browser Chrome untuk target Web.
- Android Studio/Android SDK untuk target Android.
- Xcode hanya diperlukan untuk build iOS dan macOS.
- Koneksi jaringan lokal jika Flutter dijalankan dari device berbeda dengan backend.

## Instalasi dependency Flutter

Dari root project:

```powershell
flutter pub get
```

Jika Flutter tidak terdaftar di PATH pada Windows, gunakan lokasi Flutter SDK yang terpasang di komputer.

## Menyiapkan database Laragon

Pastikan MySQL Laragon aktif pada port `3306`. Kemudian import schema:

```powershell
Get-Content .\backend\database\schema.sql -Raw |
  & 'D:\laragon\bin\mysql\mysql-8.4.3-winx64\bin\mysql.exe' `
    --host=127.0.0.1 --port=3306 --user=root
```

Jika MySQL menggunakan password, tambahkan `--password` pada perintah tersebut. Schema membuat database:

```text
lost_and_found_campus
```

Tabel yang digunakan:

- `users`: data mahasiswa yang login.
- `reports`: data laporan barang dan foto.
- `chats`: sesi percakapan klaim.
- `messages`: pesan disimpan satu per satu di server agar snapshot lokal tidak dapat menghapus pesan akun lain.
- `chat_members`: anggota sesi chat, waktu bergabung, dan waktu terakhir membaca.
- `user_presence`: status online dan waktu terakhir dilihat.
- `notifications`: notifikasi pengguna.

Chat dibuat per laporan dan pasangan pengguna. Endpoint khusus membuat sesi,
mengirim pesan, serta menandai pesan telah dibaca. Laporan tetap disinkronkan
melalui endpoint sync; endpoint tersebut tidak menulis ulang isi percakapan.

## Konfigurasi koneksi backend

Backend membaca konfigurasi dari environment variable. Contoh PowerShell:

```powershell
$env:TEMU_DB_HOST = '127.0.0.1'
$env:TEMU_DB_PORT = '3306'
$env:TEMU_DB_NAME = 'lost_and_found_campus'
$env:TEMU_DB_USER = 'root'
$env:TEMU_DB_PASSWORD = ''
$env:TEMU_CORS_ORIGIN = '*'
```

Jika MySQL Laragon berjalan pada port lain, misalnya `3307`, sesuaikan
`TEMU_DB_PORT`. Konfigurasi default juga tersedia di
[backend/config.php](backend/config.php). Jangan menyimpan password database
asli ke repository.

## Menjalankan REST API

Dari root project:

```powershell
$php = 'D:\laragon\bin\php\php-8.3.30-Win32-vs16-x64\php.exe'
& $php -S 0.0.0.0:8088 -t backend/public
```

Alamat API:

```text
http://127.0.0.1:8088/api/index.php
```

Pemeriksaan kesehatan API:

```text
GET /api/index.php?path=health
```

## Demo APK Android melalui server laptop

Demo APK membutuhkan API yang dapat diakses dari perangkat. Repository tidak
menyimpan ID tunnel, URL tunnel, path instalasi lokal, atau konfigurasi pribadi.

Konfigurasi demo disimpan di `scripts/demo.local.ps1` (diabaikan Git). Buat file
tersebut dari template:

```powershell
Copy-Item .\scripts\demo.local.example.ps1 .\scripts\demo.local.ps1
```

Isi variabel berikut sesuai komputer demo:

- `TEMU_TUNNEL_ID`: ID tunnel Dev Tunnels.
- `TEMU_PUBLIC_API_URL`: URL API publik yang dipakai APK.
- `TEMU_PHP_EXE`: path `php.exe` bila tidak tersedia di `PATH`.
- `TEMU_DEVTUNNEL_EXE`: path `devtunnel.exe` bila tidak tersedia di `PATH`.
- `TEMU_MYSQL_SERVICE`: nama service MySQL, default `MySQL80`.
- `TEMU_DB_PORT`: port MySQL, default `3306`.
- `TEMU_API_PORT`: port API lokal, default `8088`.

Setelah konfigurasi siap, jalankan `MULAI_SERVER_TEMU.bat` sebagai Administrator.
Script akan:

- menyalakan service MySQL jika service tersedia dan belum berjalan;
- memeriksa koneksi database pada port yang dikonfigurasi;
- memperpanjang tunnel dan membuka akses anonim sementara;
- menjalankan API PHP dan memeriksa endpoint health;
- menutup tunnel, API, dan MySQL yang disalakan script saat `Ctrl+C`.

APK uji harus dibangun dengan URL yang sama:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://<tunnel-anda>-8088.asse.devtunnels.ms/api/index.php
```

APK uji yang dibangun sebelumnya berada di luar repository dan hanya berlaku
selama tunnel demo masih aktif. APK tersebut belum siap untuk distribusi resmi.

Tunnel diperpanjang hingga 30 hari tanpa aktivitas setiap kali script berjalan.
Jika tidak digunakan lebih dari 30 hari, tunnel dapat kedaluwarsa dan perlu
dibuat ulang. Akses anonim hanya dibuka saat demo dan kedaluwarsa otomatis
setelah 4 jam.

Endpoint yang tersedia:

| Method | Endpoint | Keterangan |
|---|---|---|
| POST | `?path=auth/login` | Validasi email kampus dan menyimpan pengguna |
| POST | `?path=auth/admin-login` | Verifikasi admin dan menghasilkan token sesi |
| POST | `?path=presence` | Memperbarui status online atau last seen |
| POST | `?path=chats/start` | Memulai atau membuka percakapan untuk laporan dan pengguna |
| POST | `?path=messages/send` | Menyimpan pesan dan membuat notifikasi penerima |
| POST | `?path=chats/read` | Memperbarui waktu dibaca serta unread count akun |
| POST | `?path=notifications/read-all` | Menandai notifikasi akun telah dibaca |
| GET | `?path=sync&email=...` | Mengambil laporan, chat, dan notifikasi |
| GET | `?path=admin/sync` | Mengambil seluruh data untuk dashboard admin dengan header token |
| POST | `?path=sync` | Menyimpan sinkronisasi data aplikasi |
| DELETE | `?path=reports&email=...&id=...` | Menghapus laporan hanya oleh pemiliknya |

Dokumentasi backend yang lebih spesifik tersedia di [backend/README.md](backend/README.md).

## Menjalankan aplikasi Flutter

### Demo cepat melalui VS Code (Windows)

1. Buka seluruh folder project ini di VS Code.
2. Jalankan MySQL dari Laragon dan pastikan database `lost_and_found_campus` sudah tersedia.
3. Pasang ekstensi **Flutter** di VS Code jika belum ada.
4. Buka **Run and Debug**, pilih **TEMU - Demo Web di Chrome**, lalu tekan **F5**.

Task VS Code akan memeriksa API. Jika API belum aktif, task mencoba menjalankan PHP
dari `PATH` atau instalasi Laragon standar pada `D:\laragon\bin\php`; setelah backend
dan database terhubung, Flutter dibuka di Chrome. Jika PHP Laragon berada di lokasi lain,
tambahkan `php.exe` ke `PATH` atau sesuaikan pencarian PHP di `.vscode/tasks.json`.

Untuk pertama kali, jalankan `flutter pub get` dari terminal project jika VS Code meminta
dependency Flutter disiapkan.

### Web/Chrome

API default Web menggunakan:

```text
http://127.0.0.1:8088/api/index.php
```

### Login admin demo

Pilih `Masuk sebagai admin` pada halaman login. Kredensial default backend:

```text
Email: admin@uin-malang.ac.id
Password: admin123
```

Untuk instalasi nyata, ganti melalui environment `TEMU_ADMIN_EMAIL`,
`TEMU_ADMIN_PASSWORD`, `TEMU_ADMIN_NAME`, dan `TEMU_ADMIN_SECRET`.

Jalankan:

```powershell
flutter run -d chrome
```

### Windows dan macOS

```powershell
flutter run -d windows
flutter run -d macos
```

Target macOS harus dibuild pada macOS dengan Xcode.

### Android Emulator

Android Emulator mengakses komputer host melalui `10.0.2.2`:

```powershell
flutter run -d android
```

### Device fisik

Gunakan alamat IP komputer yang menjalankan API:

```powershell
flutter run -d <device-id> `
  --dart-define=API_BASE_URL=http://192.168.1.10:8088/api/index.php
```

Pastikan device dan komputer berada pada jaringan yang sama serta firewall mengizinkan port `8088`.

### iOS Simulator

```powershell
flutter run -d ios
```

Target iOS harus dijalankan pada macOS dengan Xcode.

## Konfigurasi URL API

Flutter membaca URL backend dari `API_BASE_URL`.

Default yang digunakan:

- Web, Windows, macOS, Linux: `http://127.0.0.1:8088/api/index.php`
- Android Emulator: `http://10.0.2.2:8088/api/index.php`

Contoh mengganti URL:

```powershell
flutter run -d chrome `
  --dart-define=API_BASE_URL=http://192.168.1.10:8088/api/index.php
```

Konfigurasi tersebut diproses di [lib/services/api_service.dart](lib/services/api_service.dart).

## Pengujian dan pemeriksaan

Format kode:

```powershell
dart format lib
```

Static analysis:

```powershell
flutter analyze --no-pub
```

Unit/widget test:

```powershell
flutter test --no-pub
```

Build Web:

```powershell
flutter build web --no-pub --no-web-resources-cdn
```

Pemeriksaan sintaks backend:

```powershell
php -l backend/config.php
php -l backend/public/api/index.php
```

## Dokumentasi tambahan

- [Audit baseline dan perbaikan fondasi](docs/AUDIT_BASELINE_FONDASI.md)
- [Lifecycle-aware upload queue dan retry](docs/LIFECYCLE_UPLOAD_QUEUE.md)
- [Laporan Tahap 4–5](docs/Laporan_Tahap_4_dan_5_TEMU_UIN_Malang.docx)

## Status implementasi MVP

Project telah memenuhi fungsi utama MVP:

- Proyek Flutter dapat dijalankan.
- Antarmuka aplikasi telah tersedia.
- Navigasi antarhalaman telah diterapkan.
- Validasi input email kampus dan form laporan telah diterapkan.
- Data laporan, chat, pesan, dan notifikasi dikelola melalui repository.
- Backend REST API dan database MySQL telah tersedia.
- Penyimpanan lokal Hive tersedia sebagai buffer perangkat tanpa mencampurkan data antar akun.
- Identitas email, NIM, dan nama dikunci di database; perubahan identitas pada email yang sama ditolak.
- Laporan milik akun lain, anggota chat, notifikasi pesan, dan presence dibaca dari database bersama.
- Antrean upload lifecycle-aware menyimpan laporan yang gagal terkirim dan mencoba ulang dengan backoff.
- Error API membawa status HTTP sehingga kegagalan validasi tidak diulang terus.
- Flutter analyze terakhir: lulus (`No issues found`) pada 26 Oktober 2026.
- PHP lint untuk `backend/config.php` dan `backend/public/api/index.php`: lulus.
- Terdapat 31 test otomatis untuk login, navigasi, laporan, pemilih foto, chat, antrean upload, dan smoke test. Eksekusi ulang pada 26 Oktober 2026 lulus (`All tests passed`).
- Uji backend live pada 26 Oktober 2026: health API berhasil, insert/update laporan oleh pemilik berhasil, dan akun lain tidak dapat menimpa laporan.
- Build Web pernah berhasil; ulangi setelah perubahan final.
- APK uji Android pernah dibangun, tetapi masih memakai debug signing dan URL dev tunnel. APK tersebut belum siap untuk distribusi resmi; build release final perlu diulang pada environment yang bersih.

## Batasan saat ini

- Login backend masih berupa validasi domain email, belum menggunakan password, OTP, atau autentikasi token.
- Chat saat ini melakukan sinkronisasi melalui API ketika terjadi perubahan; push notification/WebSocket realtime belum diterapkan.
- API menggunakan CORS terbuka untuk kebutuhan development lokal. Pada deployment produksi, CORS harus dibatasi ke domain aplikasi.
- Backend Laragon ditujukan untuk development/demo. Deployment publik memerlukan hosting, HTTPS, pengamanan credential, dan konfigurasi server produksi.
- Antrean upload berjalan saat aplikasi foreground/aktif. Background worker OS dan listener konektivitas khusus belum diterapkan.
- Item antrean yang gagal permanen (4xx) dihapus dan dicatat di log; belum ada halaman daftar kegagalan permanen.
- State recovery penuh (draft form dan auto-login) serta candidate matching hilang/temuan belum diterapkan.
- Uji calon pengguna, APK final, video, dan bahan presentasi masih harus dilengkapi. Jangan mengisi hasil uji pengguna tanpa sesi uji yang benar-benar dilakukan.

## Lisensi dan penggunaan

Project ini dibuat untuk kebutuhan pembelajaran dan pengembangan aplikasi Lost & Found UIN Malang.
