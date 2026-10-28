# Salin file ini menjadi scripts/demo.local.ps1, lalu isi nilainya.
# File demo.local.ps1 diabaikan Git agar konfigurasi pribadi tidak terpublikasi.

$env:TEMU_TUNNEL_ID = 'temu-...'
$env:TEMU_PUBLIC_API_URL = 'https://<tunnel-anda>-8088.asse.devtunnels.ms/api/index.php'
$env:TEMU_PHP_EXE = 'C:\path\ke\php.exe'
$env:TEMU_DEVTUNNEL_EXE = 'C:\path\ke\devtunnel.exe'
$env:TEMU_API_PORT = '8088'

# Database bawaan memakai Laragon di port 3307. Skrip akan menyalakan
# mysqld Laragon langsung bila port ini belum terbuka.
$env:TEMU_DB_PORT = '3307'
# Opsional: tentukan sendiri biner dan konfigurasi MySQL Laragon.
# $env:TEMU_MYSQL_EXE = 'D:\laragon\bin\mysql\mysql-8.4.3-winx64\bin\mysqld.exe'
# $env:TEMU_MYSQL_INI = 'D:\laragon\bin\mysql\mysql-8.4.3-winx64\my.ini'

# Cadangan bila memakai service Windows, bukan Laragon.
$env:TEMU_MYSQL_SERVICE = 'MySQL80'
