# Backend TEMU UIN Malang

Backend REST API sederhana untuk demo akademik menggunakan PHP + MySQL/MariaDB Laragon.

## 1. Siapkan database

Import file `database/schema.sql` melalui phpMyAdmin Laragon atau MySQL CLI.

Untuk database yang sudah pernah dibuat sebelum fitur multi-akun, jalankan juga
`database/migrations/001_multi_user_interaction.sql` dan
`database/migrations/002_mutual_claims_and_message_unsend.sql` satu kali,
berurutan.

Contoh CLI PowerShell:

```powershell
Get-Content .\database\schema.sql -Raw |
  & 'D:\laragon\bin\mysql\mysql-8.4.3-winx64\bin\mysql.exe' `
    --host=127.0.0.1 --port=3306 --user=root --password
```

## 2. Atur koneksi

Salin `config.php` sebagai acuan dan isi password MySQL sesuai instalasi Laragon. Konfigurasi dapat diberikan melalui environment:

```powershell
$env:TEMU_DB_HOST = '127.0.0.1'
$env:TEMU_DB_PORT = '3306'
$env:TEMU_DB_NAME = 'lost_and_found_campus'
$env:TEMU_DB_USER = 'root'
$env:TEMU_DB_PASSWORD = 'password_mysql'
$env:TEMU_ADMIN_EMAIL = 'admin@uin-malang.ac.id'
$env:TEMU_ADMIN_PASSWORD = 'ganti-password-admin'
$env:TEMU_ADMIN_NAME = 'Administrator TEMU'
$env:TEMU_ADMIN_SECRET = 'ganti-secret-token-admin'
```

## 3. Jalankan API lokal

Dari root project:

```powershell
php -S 0.0.0.0:8088 -t backend/public
```

Endpoint API berada di:

```
http://127.0.0.1:8088/api/index.php
```

Contoh pemeriksaan:

```
GET /api/index.php?path=health
```

## Endpoint

- `POST ?path=auth/login`
- `POST ?path=auth/admin-login`
- `POST ?path=presence`
- `POST ?path=chats/start`
- `POST ?path=claims/request` (pengaju meminta klaim atas laporan)
- `POST ?path=claims/respond` (pemilik menyetujui atau menolak permintaan)
- `POST ?path=messages/send`
- `DELETE ?path=messages&email=...&id=...` (pengirim membatalkan pesannya sendiri)
- `POST ?path=chats/read`
- `POST ?path=notifications/read-all`
- `GET ?path=sync&email=nim@student.uin-malang.ac.id`
- `GET ?path=admin/sync` dengan header `X-Admin-Token`
- `POST ?path=sync`
- `DELETE ?path=reports&email=...&id=...` hanya untuk pemilik laporan

Permintaan klaim mengubah status menjadi `prosesKlaim`; hanya pemilik laporan
yang dapat menyetujui atau menolak. Persetujuan menandai laporan `selesai`,
sedangkan penolakan mengembalikannya menjadi `belumDiklaim`. Pesan yang
dibatalkan dihapus untuk kedua anggota chat; notifikasi yang terkait ikut
terhapus melalui foreign key.

Backend menjadi sumber data bersama untuk semua akun. Endpoint sync hanya
memperbarui laporan; pesan ditambahkan melalui `messages/send`, sehingga
snapshot perangkat tidak dapat menghapus pesan pengguna lain. Status online
diperbarui tiap lima detik dan ditandai offline setelah heartbeat berhenti.
