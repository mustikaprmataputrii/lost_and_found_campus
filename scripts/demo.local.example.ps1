# Salin file ini menjadi scripts/demo.local.ps1, lalu isi nilainya.
# File demo.local.ps1 diabaikan Git agar konfigurasi pribadi tidak terpublikasi.

$env:TEMU_TUNNEL_ID = 'temu-...'
$env:TEMU_PUBLIC_API_URL = 'https://<tunnel-anda>-8088.asse.devtunnels.ms/api/index.php'
$env:TEMU_PHP_EXE = 'C:\path\ke\php.exe'
$env:TEMU_DEVTUNNEL_EXE = 'C:\path\ke\devtunnel.exe'
$env:TEMU_MYSQL_SERVICE = 'MySQL80'
$env:TEMU_DB_PORT = '3306'
$env:TEMU_API_PORT = '8088'
