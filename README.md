# TEMU UIN Malang

Aplikasi Lost & Found kampus untuk membantu mahasiswa UIN Maulana Malik Ibrahim Malang melaporkan, mencari, dan mengklaim barang hilang atau ditemukan.

Project ini dibuat menggunakan Flutter dan memiliki backend REST API berbasis PHP + MySQL/MariaDB yang dapat dijalankan melalui Laragon.

## Fitur utama

- Login hanya menggunakan email resmi mahasiswa dengan format:
  `NIM@student.uin-malang.ac.id`
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
- Cache/fallback lokal menggunakan Hive agar aplikasi tetap dapat dibuka saat API offline.
- Dukungan target Flutter Web, Android, iOS, Windows, macOS, dan Linux sesuai ketersediaan toolchain perangkat.

## Arsitektur aplikasi

```text
Flutter UI
   |
   +-- AppDataRepository
          |
          +-- ApiService
          |      |
          |      +-- PHP REST API
          |             |
          |             +-- MySQL/MariaDB Laragon
          |
          +-- LocalDataRepository
                 |
                 +-- Hive cache/fallback
```

Aplikasi mencoba mengambil data dari backend terlebih dahulu. Jika API tidak dapat diakses, aplikasi menggunakan cache Hive yang tersimpan di perangkat. Perubahan laporan, chat, pesan, status klaim, dan notifikasi disimpan ke cache lalu dikirim ke backend ketika API tersedia.

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
│   └── app_services.dart      # Auth dan session service
├── widgets/                   # Komponen UI yang digunakan bersama
└── main.dart                  # Entry point dan registrasi modul

backend/
├── database/schema.sql        # Struktur database MySQL
├── public/api/index.php       # REST API PHP
├── config.php                 # Konfigurasi koneksi database
└── README.md                  # Panduan backend
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
- `messages`: pesan dalam sesi chat.
- `notifications`: notifikasi pengguna.

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

Konfigurasi default juga tersedia di [backend/config.php](backend/config.php). Jangan menyimpan password database asli ke repository.

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

Endpoint yang tersedia:

| Method | Endpoint | Keterangan |
|---|---|---|
| POST | `?path=auth/login` | Validasi email kampus dan menyimpan pengguna |
| POST | `?path=auth/admin-login` | Verifikasi admin dan menghasilkan token sesi |
| GET | `?path=sync&email=...` | Mengambil laporan, chat, dan notifikasi |
| GET | `?path=admin/sync` | Mengambil seluruh data untuk dashboard admin dengan header token |
| POST | `?path=sync` | Menyimpan sinkronisasi data aplikasi |

Dokumentasi backend yang lebih spesifik tersedia di [backend/README.md](backend/README.md).

## Menjalankan aplikasi Flutter

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

## Status implementasi MVP

Project telah memenuhi fungsi utama MVP:

- Proyek Flutter dapat dijalankan.
- Antarmuka aplikasi telah tersedia.
- Navigasi antarhalaman telah diterapkan.
- Validasi input email kampus dan form laporan telah diterapkan.
- Data laporan, chat, pesan, dan notifikasi dikelola melalui repository.
- Backend REST API dan database MySQL telah tersedia.
- Penyimpanan lokal Hive tersedia sebagai cache/fallback.
- Build Web dan test Flutter telah divalidasi.

## Batasan saat ini

- Login backend masih berupa validasi domain email, belum menggunakan password, OTP, atau autentikasi token.
- Chat saat ini melakukan sinkronisasi melalui API ketika terjadi perubahan; push notification/WebSocket realtime belum diterapkan.
- API menggunakan CORS terbuka untuk kebutuhan development lokal. Pada deployment produksi, CORS harus dibatasi ke domain aplikasi.
- Backend Laragon ditujukan untuk development/demo. Deployment publik memerlukan hosting, HTTPS, pengamanan credential, dan konfigurasi server produksi.

## Lisensi dan penggunaan

Project ini dibuat untuk kebutuhan pembelajaran dan pengembangan aplikasi Lost & Found UIN Malang.
