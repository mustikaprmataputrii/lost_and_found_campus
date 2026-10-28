$ErrorActionPreference = 'Stop'

# Konfigurasi lokal opsional agar ID tunnel dan path pribadi tidak masuk repo.
$localConfig = Join-Path $PSScriptRoot 'demo.local.ps1'
if (Test-Path -LiteralPath $localConfig) {
    . $localConfig
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$publicRoot = Join-Path $projectRoot 'backend\public'
$mysqlServiceName = if ($env:TEMU_MYSQL_SERVICE) { $env:TEMU_MYSQL_SERVICE } else { 'MySQL80' }
$dbPort = if ($env:TEMU_DB_PORT) { [int]$env:TEMU_DB_PORT } else { 3306 }
$mysqlExe = $env:TEMU_MYSQL_EXE
$mysqlIni = $env:TEMU_MYSQL_INI
$apiPort = if ($env:TEMU_API_PORT) { [int]$env:TEMU_API_PORT } else { 8088 }
$healthUrl = "http://127.0.0.1:$apiPort/api/index.php?path=health"
$tunnelId = $env:TEMU_TUNNEL_ID
$publicApiUrl = $env:TEMU_PUBLIC_API_URL

$phpExe = $env:TEMU_PHP_EXE
if (-not $phpExe) {
    $phpCommand = Get-Command php -ErrorAction SilentlyContinue
    if ($phpCommand) {
        $phpExe = $phpCommand.Source
    }
}
if (-not $phpExe) {
    $laragonPhp = Get-ChildItem 'D:\laragon\bin\php\php-*\php.exe' -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if ($laragonPhp) {
        $phpExe = $laragonPhp.FullName
    }
}

$devTunnelExe = $env:TEMU_DEVTUNNEL_EXE
if (-not $devTunnelExe) {
    $devTunnelCommand = Get-Command devtunnel -ErrorAction SilentlyContinue
    if ($devTunnelCommand) {
        $devTunnelExe = $devTunnelCommand.Source
    }
}
if (-not $devTunnelExe -and (Test-Path -LiteralPath 'D:\laragon\bin\devtunnel.exe')) {
    $devTunnelExe = 'D:\laragon\bin\devtunnel.exe'
}

if (-not $mysqlExe) {
    $laragonMysqld = Get-ChildItem 'D:\laragon\bin\mysql\mysql-*\bin\mysqld.exe' -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if ($laragonMysqld) {
        $mysqlExe = $laragonMysqld.FullName
    }
}
if (-not $mysqlExe) {
    $mysqldCommand = Get-Command mysqld -ErrorAction SilentlyContinue
    if ($mysqldCommand) {
        $mysqlExe = $mysqldCommand.Source
    }
}
if ($mysqlExe -and -not $mysqlIni) {
    $candidateIni = Join-Path (Split-Path -Parent (Split-Path -Parent $mysqlExe)) 'my.ini'
    if (Test-Path -LiteralPath $candidateIni) {
        $mysqlIni = $candidateIni
    }
}
$mysqlAdminExe = if ($mysqlExe) { Join-Path (Split-Path -Parent $mysqlExe) 'mysqladmin.exe' } else { $null }

function Test-TcpPort {
    param([int]$Port)

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $client.Connect('127.0.0.1', $Port)
        return $true
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = "-NoProfile -NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments
    exit
}

if (-not $tunnelId) {
    throw 'TEMU_TUNNEL_ID belum diatur. Isi scripts/demo.local.ps1 atau environment variable.'
}
if (-not $phpExe) {
    throw 'PHP tidak ditemukan. Atur TEMU_PHP_EXE atau tambahkan php.exe ke PATH.'
}
if (-not $devTunnelExe) {
    throw 'Dev Tunnels CLI tidak ditemukan. Atur TEMU_DEVTUNNEL_EXE atau tambahkan devtunnel.exe ke PATH.'
}
if (-not (Test-Path -LiteralPath $phpExe)) {
    throw "PHP tidak ditemukan: $phpExe"
}
if (-not (Test-Path -LiteralPath $devTunnelExe)) {
    throw "Dev Tunnels CLI tidak ditemukan: $devTunnelExe"
}
if (-not (Test-Path -LiteralPath $publicRoot)) {
    throw "Folder API tidak ditemukan: $publicRoot"
}
if (Test-TcpPort -Port $apiPort) {
    throw "Port $apiPort sudah digunakan. Tutup server API lain sebelum menjalankan demo."
}

$mysqlStartedByScript = $false
$mysqlProcess = $null
$phpProcess = $null
$anonymousAccessOpened = $false
$stdoutLog = Join-Path $env:TEMP 'temu-api.stdout.log'
$stderrLog = Join-Path $env:TEMP 'temu-api.stderr.log'
$mysqlStdoutLog = Join-Path $env:TEMP 'temu-mysql.stdout.log'
$mysqlStderrLog = Join-Path $env:TEMP 'temu-mysql.stderr.log'

function Stop-TemuMysql {
    param([System.Diagnostics.Process]$Process)

    if ($null -eq $Process -or $Process.HasExited) {
        return
    }
    if ($mysqlAdminExe -and (Test-Path -LiteralPath $mysqlAdminExe)) {
        & $mysqlAdminExe --host=127.0.0.1 "--port=$dbPort" --user=root shutdown 2>$null | Out-Null
    }
    if (-not $Process.WaitForExit(15000)) {
        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
    }
}

try {
    if (-not (Test-TcpPort -Port $dbPort)) {
        $startedLaragonMysql = $false
        if ($mysqlExe -and $mysqlIni -and (Test-Path -LiteralPath $mysqlExe) -and (Test-Path -LiteralPath $mysqlIni)) {
            Write-Host "Menyalakan MySQL Laragon pada port $dbPort..."
            $mysqlProcess = Start-Process -FilePath $mysqlExe `
                -ArgumentList @("--defaults-file=$mysqlIni", "--port=$dbPort", '--mysqlx=0') `
                -WorkingDirectory (Split-Path -Parent $mysqlExe) `
                -WindowStyle Hidden `
                -PassThru `
                -RedirectStandardOutput $mysqlStdoutLog `
                -RedirectStandardError $mysqlStderrLog
            $startedLaragonMysql = $true
            $mysqlStartedByScript = $true
        }
        if (-not $startedLaragonMysql) {
            $mysqlService = Get-Service -Name $mysqlServiceName -ErrorAction SilentlyContinue
            if ($null -eq $mysqlService) {
                throw "MySQL belum berjalan pada port $dbPort dan tidak ada mysqld Laragon maupun service '$mysqlServiceName'. Atur TEMU_MYSQL_EXE/TEMU_MYSQL_INI atau TEMU_MYSQL_SERVICE."
            }
            if ($mysqlService.Status -ne 'Running') {
                Start-Service -Name $mysqlServiceName
                $mysqlStartedByScript = $true
                (Get-Service -Name $mysqlServiceName).WaitForStatus('Running', [TimeSpan]::FromSeconds(45))
            }
        }
    }

    $mysqlReady = $false
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        if (Test-TcpPort -Port $dbPort) {
            $mysqlReady = $true
            break
        }
        Start-Sleep -Seconds 1
    }
    if (-not $mysqlReady) {
        if (Test-Path -LiteralPath $mysqlStderrLog) {
            Get-Content -LiteralPath $mysqlStderrLog -Tail 20 | Out-Host
        }
        throw "MySQL tidak siap pada port $dbPort. Periksa log: $mysqlStderrLog"
    }

    & $devTunnelExe update $tunnelId --expiration 30d | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw 'Tunnel tidak ditemukan atau sudah kedaluwarsa. Perlu diperbarui sebelum APK dapat digunakan.'
    }

    & $devTunnelExe access reset $tunnelId | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Pengaturan akses tunnel gagal direset.'
    }
    & $devTunnelExe access create $tunnelId --anonymous --expiration 4h | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw 'Akses sementara untuk APK gagal diaktifkan.'
    }
    $anonymousAccessOpened = $true

    $env:TEMU_DB_PORT = "$dbPort"
    $phpProcess = Start-Process -FilePath $phpExe `
        -ArgumentList @('-S', "127.0.0.1:$apiPort", '-t', '.') `
        -WorkingDirectory $publicRoot `
        -WindowStyle Hidden `
        -PassThru `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog

    $apiReady = $false
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        try {
            $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 3
            if ($health.ok -and $health.database -eq 'connected') {
                $apiReady = $true
                break
            }
        } catch {
        }
        Start-Sleep -Seconds 1
    }
    if (-not $apiReady) {
        if (Test-Path -LiteralPath $stderrLog) {
            Get-Content -LiteralPath $stderrLog -Tail 20 | Out-Host
        }
        throw 'API belum sehat atau tidak tersambung ke database. Periksa konfigurasi database backend.'
    }

    Write-Host ''
    Write-Host 'TEMU siap untuk demo Android.' -ForegroundColor Green
    Write-Host "Health API: $healthUrl"
    if ($publicApiUrl) {
        Write-Host "URL API APK: $publicApiUrl"
    } else {
        Write-Host 'URL API APK: atur TEMU_PUBLIC_API_URL di scripts/demo.local.ps1.'
    }
    Write-Host 'Tunnel dibuka anonim selama maksimal 4 jam. Jaga jendela ini tetap terbuka.'
    Write-Host 'Tekan Ctrl+C untuk menutup tunnel dan API.'
    Write-Host ''

    & $devTunnelExe host $tunnelId
    if ($LASTEXITCODE -ne 0) {
        throw 'Proses host tunnel berhenti dengan error.'
    }
} finally {
    if ($anonymousAccessOpened) {
        & $devTunnelExe access reset $tunnelId | Out-Null
    }
    if ($null -ne $phpProcess -and -not $phpProcess.HasExited) {
        Stop-Process -Id $phpProcess.Id -Force -ErrorAction SilentlyContinue
    }
    if ($null -ne $mysqlProcess) {
        Stop-TemuMysql -Process $mysqlProcess
    } elseif ($mysqlStartedByScript) {
        Stop-Service -Name $mysqlServiceName -ErrorAction SilentlyContinue
    }
    Write-Host 'Sesi demo selesai. Akses publik dan API sudah ditutup.'
}
