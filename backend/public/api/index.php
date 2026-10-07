<?php

declare(strict_types=1);

$config = require __DIR__ . '/../../config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: ' . $config['cors_origin']);
header('Access-Control-Allow-Headers: Content-Type, Accept');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function respond(array $payload, int $status = 200): never
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function requestBody(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return [];
    }

    $body = json_decode($raw, true);
    return is_array($body) ? $body : [];
}

function campusEmailIsValid(string $email): bool
{
    return preg_match('/^\d+@student\.uin-malang\.ac\.id$/i', $email) === 1;
}

function databaseDate(mixed $value): string
{
    $timestamp = strtotime((string) $value);
    return date('Y-m-d H:i:s', $timestamp === false ? time() : $timestamp);
}

function isoDate(?string $value): ?string
{
    if ($value === null || $value === '') {
        return null;
    }

    $timestamp = strtotime($value);
    return $timestamp === false ? null : gmdate('c', $timestamp);
}

function requireString(array $body, string $key): string
{
    return trim((string) ($body[$key] ?? ''));
}

$dbConfig = $config['database'];
$db = @new mysqli(
    $dbConfig['host'],
    $dbConfig['user'],
    $dbConfig['password'],
    $dbConfig['name'],
    $dbConfig['port'],
);

if ($db->connect_errno) {
    respond([
        'ok' => false,
        'error' => 'Database belum terhubung. Periksa backend/config.php atau kredensial MySQL Laragon.',
    ], 503);
}

$db->set_charset('utf8mb4');

$method = $_SERVER['REQUEST_METHOD'];
$path = trim((string) ($_GET['path'] ?? ''), '/');
$body = requestBody();

function ensureUser(mysqli $db, string $email, string $nim, string $nama): void
{
    $statement = $db->prepare(
        'INSERT INTO users (nim, email, nama) VALUES (?, ?, ?)
         ON DUPLICATE KEY UPDATE nim = VALUES(nim), nama = VALUES(nama)',
    );
    $statement->bind_param('sss', $nim, $email, $nama);
    $statement->execute();
    $statement->close();
}

if ($method === 'GET' && $path === 'health') {
    respond([
        'ok' => true,
        'service' => 'TEMU UIN Malang API',
        'database' => 'connected',
    ]);
}

if ($method === 'POST' && $path === 'auth/login') {
    $email = strtolower(requireString($body, 'email'));
    $nim = requireString($body, 'nim');
    $nama = requireString($body, 'nama');

    if (!campusEmailIsValid($email)) {
        respond([
            'ok' => false,
            'error' => 'Gunakan email resmi mahasiswa UIN Malang.',
        ], 422);
    }

    if ($nim === '') {
        $nim = explode('@', $email)[0];
    }
    if ($nama === '') {
        $nama = $nim;
    }

    ensureUser($db, $email, $nim, $nama);
    respond([
        'ok' => true,
        'data' => [
            'email' => $email,
            'nim' => $nim,
            'nama' => $nama,
        ],
    ]);
}

if ($path !== 'sync') {
    respond(['ok' => false, 'error' => 'Endpoint tidak ditemukan.'], 404);
}

$email = strtolower(trim((string) ($body['email'] ?? $_GET['email'] ?? '')));
if (!campusEmailIsValid($email)) {
    respond(['ok' => false, 'error' => 'Email kampus tidak valid.'], 422);
}

if ($method === 'GET') {
    $reports = [];
    $reportResult = $db->query(
        'SELECT id, nama, lokasi, deskripsi, jenis, pelapor, kontak,
                tanggal, foto, status
         FROM reports
         ORDER BY tanggal DESC',
    );
    while ($row = $reportResult->fetch_assoc()) {
        $row['tanggal'] = isoDate($row['tanggal']);
        $reports[] = $row;
    }

    $chats = [];
    $chatStatement = $db->prepare(
        'SELECT c.id AS chat_id, c.is_online, c.last_seen, c.unread_count,
                r.id AS report_id, r.nama, r.lokasi, r.deskripsi, r.jenis,
                r.pelapor, r.kontak, r.tanggal, r.foto, r.status
         FROM chats c
         INNER JOIN reports r ON r.id = c.barang_id
         WHERE c.owner_email = ? OR c.owner_email IS NULL
         ORDER BY c.updated_at DESC',
    );
    $chatStatement->bind_param('s', $email);
    $chatStatement->execute();
    $chatRows = $chatStatement->get_result();

    $messageStatement = $db->prepare(
        'SELECT pengirim, teks, waktu, is_me
         FROM messages
         WHERE chat_id = ?
         ORDER BY waktu ASC, id ASC',
    );

    while ($row = $chatRows->fetch_assoc()) {
        $messageStatement->bind_param('s', $row['chat_id']);
        $messageStatement->execute();
        $messageRows = $messageStatement->get_result();
        $messages = [];

        while ($message = $messageRows->fetch_assoc()) {
            $messages[] = [
                'pengirim' => $message['pengirim'],
                'teks' => $message['teks'],
                'waktu' => isoDate($message['waktu']),
                'isMe' => (bool) $message['is_me'],
            ];
        }

        $chats[] = [
            'id' => $row['chat_id'],
            'barang' => [
                'id' => $row['report_id'],
                'nama' => $row['nama'],
                'lokasi' => $row['lokasi'],
                'deskripsi' => $row['deskripsi'],
                'jenis' => $row['jenis'],
                'pelapor' => $row['pelapor'],
                'kontak' => $row['kontak'],
                'tanggal' => isoDate($row['tanggal']),
                'foto' => $row['foto'],
                'status' => $row['status'],
            ],
            'pesanList' => $messages,
            'isOnline' => (bool) $row['is_online'],
            'lastSeen' => isoDate($row['last_seen']),
            'unreadCount' => (int) $row['unread_count'],
        ];
    }

    $messageStatement->close();
    $chatStatement->close();

    $notifications = [];
    $notificationStatement = $db->prepare(
        'SELECT title, message, waktu, is_read
         FROM notifications
         WHERE email = ?
         ORDER BY waktu DESC',
    );
    $notificationStatement->bind_param('s', $email);
    $notificationStatement->execute();
    $notificationRows = $notificationStatement->get_result();

    while ($notification = $notificationRows->fetch_assoc()) {
        $notifications[] = [
            'title' => $notification['title'],
            'message' => $notification['message'],
            'waktu' => isoDate($notification['waktu']),
            'isRead' => (bool) $notification['is_read'],
        ];
    }

    $notificationStatement->close();
    respond([
        'ok' => true,
        'data' => [
            'reports' => $reports,
            'chats' => $chats,
            'notifications' => $notifications,
        ],
    ]);
}

if ($method !== 'POST') {
    respond(['ok' => false, 'error' => 'Method tidak didukung.'], 405);
}

$nim = explode('@', $email)[0];
$nama = trim((string) ($body['nama'] ?? $nim));
ensureUser($db, $email, $nim, $nama);

$reports = is_array($body['reports'] ?? null) ? $body['reports'] : [];
$chats = is_array($body['chats'] ?? null) ? $body['chats'] : [];
$notifications = is_array($body['notifications'] ?? null)
    ? $body['notifications']
    : [];

try {
    $db->begin_transaction();

    $reportStatement = $db->prepare(
        'INSERT INTO reports
          (id, nama, lokasi, deskripsi, jenis, pelapor, kontak, tanggal, foto,
           status, user_email)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
           nama = VALUES(nama), lokasi = VALUES(lokasi),
           deskripsi = VALUES(deskripsi), jenis = VALUES(jenis),
           pelapor = VALUES(pelapor), kontak = VALUES(kontak),
           tanggal = VALUES(tanggal), foto = VALUES(foto),
           status = VALUES(status), user_email = VALUES(user_email)',
    );

    foreach ($reports as $report) {
        if (!is_array($report)) {
            continue;
        }

        $id = (string) ($report['id'] ?? '');
        if ($id === '') {
            continue;
        }

        $reportName = (string) ($report['nama'] ?? '');
        $location = (string) ($report['lokasi'] ?? '');
        $description = (string) ($report['deskripsi'] ?? '');
        $type = (string) ($report['jenis'] ?? 'ditemukan');
        $reporter = (string) ($report['pelapor'] ?? $nama);
        $contact = (string) ($report['kontak'] ?? '');
        $date = databaseDate($report['tanggal'] ?? null);
        $photo = isset($report['foto']) && $report['foto'] !== ''
            ? (string) $report['foto']
            : null;
        $status = (string) ($report['status'] ?? 'belumDiklaim');

        $reportStatement->bind_param(
            'sssssssssss',
            $id,
            $reportName,
            $location,
            $description,
            $type,
            $reporter,
            $contact,
            $date,
            $photo,
            $status,
            $email,
        );
        $reportStatement->execute();
    }
    $reportStatement->close();

    $chatStatement = $db->prepare(
        'INSERT INTO chats
          (id, barang_id, owner_email, is_online, last_seen, unread_count)
         VALUES (?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
           barang_id = VALUES(barang_id), owner_email = VALUES(owner_email),
           is_online = VALUES(is_online), last_seen = VALUES(last_seen),
           unread_count = VALUES(unread_count)',
    );
    $deleteMessageStatement = $db->prepare(
        'DELETE FROM messages WHERE chat_id = ?',
    );
    $messageStatement = $db->prepare(
        'INSERT INTO messages (chat_id, pengirim, teks, waktu, is_me)
         VALUES (?, ?, ?, ?, ?)',
    );

    foreach ($chats as $chat) {
        if (!is_array($chat)) {
            continue;
        }

        $chatId = (string) ($chat['id'] ?? '');
        $barang = is_array($chat['barang'] ?? null) ? $chat['barang'] : [];
        $barangId = (string) ($barang['id'] ?? '');
        if ($chatId === '' || $barangId === '') {
            continue;
        }

        $online = !empty($chat['isOnline']) ? 1 : 0;
        $lastSeen = isset($chat['lastSeen']) ? databaseDate($chat['lastSeen']) : null;
        $unread = (int) ($chat['unreadCount'] ?? 0);

        $chatStatement->bind_param(
            'sssisi',
            $chatId,
            $barangId,
            $email,
            $online,
            $lastSeen,
            $unread,
        );
        $chatStatement->execute();

        $deleteMessageStatement->bind_param('s', $chatId);
        $deleteMessageStatement->execute();

        $messages = is_array($chat['pesanList'] ?? null)
            ? $chat['pesanList']
            : [];
        foreach ($messages as $message) {
            if (!is_array($message)) {
                continue;
            }

            $sender = (string) ($message['pengirim'] ?? '');
            $text = (string) ($message['teks'] ?? '');
            $time = databaseDate($message['waktu'] ?? null);
            $isMe = !empty($message['isMe']) ? 1 : 0;

            $messageStatement->bind_param(
                'ssssi',
                $chatId,
                $sender,
                $text,
                $time,
                $isMe,
            );
            $messageStatement->execute();
        }
    }

    $chatStatement->close();
    $deleteMessageStatement->close();
    $messageStatement->close();

    $notificationStatement = $db->prepare(
        'INSERT INTO notifications
          (notification_key, email, title, message, waktu, is_read)
         VALUES (?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
           title = VALUES(title), message = VALUES(message),
           waktu = VALUES(waktu), is_read = VALUES(is_read)',
    );

    foreach ($notifications as $notification) {
        if (!is_array($notification)) {
            continue;
        }

        $title = (string) ($notification['title'] ?? '');
        $message = (string) ($notification['message'] ?? '');
        $time = databaseDate($notification['waktu'] ?? null);
        $isRead = !empty($notification['isRead']) ? 1 : 0;
        $notificationKey = hash(
            'sha256',
            implode('|', [$email, $title, $message, $time]),
        );

        $notificationStatement->bind_param(
            'sssssi',
            $notificationKey,
            $email,
            $title,
            $message,
            $time,
            $isRead,
        );
        $notificationStatement->execute();
    }

    $notificationStatement->close();
    $db->commit();

    respond(['ok' => true, 'data' => ['saved' => true]]);
} catch (Throwable $error) {
    $db->rollback();
    respond([
        'ok' => false,
        'error' => 'Data gagal disimpan ke database.',
    ], 500);
}

