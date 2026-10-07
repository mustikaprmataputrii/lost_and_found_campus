# Backend TEMU UIN Malang

Backend REST API sederhana untuk demo akademik menggunakan PHP + MySQL/MariaDB Laragon.

## 1. Siapkan database

Import file `database/schema.sql` melalui phpMyAdmin Laragon atau MySQL CLI.

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
- `GET ?path=sync&email=nim@student.uin-malang.ac.id`
- `GET ?path=admin/sync` dengan header `X-Admin-Token`
- `POST ?path=sync`

Flutter mencoba backend terlebih dahulu dan menggunakan Hive sebagai cache/fallback apabila API belum tersedia.
