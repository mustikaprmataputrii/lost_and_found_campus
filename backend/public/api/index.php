<?php

declare(strict_types=1);

$config = require __DIR__ . '/../../config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: ' . $config['cors_origin']);
header('Access-Control-Allow-Headers: Content-Type, Accept');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');

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

function createAdminToken(string $email, string $secret, int $expires): string
{
    $payload = $email . '|' . $expires;
    return $expires . '.' . hash_hmac('sha256', $payload, $secret);
}

function adminTokenIsValid(string $token, string $email, string $secret): bool
{
    $parts = explode('.', $token, 2);
    if (count($parts) !== 2 || !ctype_digit($parts[0])) {
        return false;
    }

    $expires = (int) $parts[0];
    if ($expires < time()) {
        return false;
    }

    $expected = createAdminToken($email, $secret, $expires);
    return hash_equals($expected, $token);
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

function ensureUser(mysqli $db, string $email, string $nim, string $nama): ?string
{
    $existing = $db->prepare('SELECT nim, nama FROM users WHERE email = ? LIMIT 1');
    $existing->bind_param('s', $email);
    $existing->execute();
    $row = $existing->get_result()->fetch_assoc();
    $existing->close();

    if ($row !== null) {
        if ((string) $row['nim'] !== $nim || (string) $row['nama'] !== $nama) {
            return 'Email ini sudah terdaftar dengan nama dan NIM yang berbeda.';
        }
        return null;
    }

    $statement = $db->prepare(
        'INSERT INTO users (nim, email, nama) VALUES (?, ?, ?)',
    );
    $statement->bind_param('sss', $nim, $email, $nama);
    $statement->execute();
    $statement->close();
    return null;
}

function setPresence(mysqli $db, string $email, bool $isOnline): void
{
    $statement = $db->prepare(
        'INSERT INTO user_presence (email, is_online, last_seen)
         VALUES (?, ?, UTC_TIMESTAMP())
         ON DUPLICATE KEY UPDATE is_online = VALUES(is_online), last_seen = VALUES(last_seen)',
    );
    $online = $isOnline ? 1 : 0;
    $statement->bind_param('si', $email, $online);
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

    $identityError = ensureUser($db, $email, $nim, $nama);
    if ($identityError !== null) {
        respond(['ok' => false, 'error' => $identityError], 409);
    }
    setPresence($db, $email, true);
    respond([
        'ok' => true,
        'data' => [
            'email' => $email,
            'nim' => $nim,
            'nama' => $nama,
        ],
    ]);
}

if ($method === 'POST' && $path === 'presence') {
    $email = strtolower(requireString($body, 'email'));
    $isOnline = !empty($body['isOnline']);
    if (!campusEmailIsValid($email)) {
        respond(['ok' => false, 'error' => 'Email kampus tidak valid.'], 422);
    }
    setPresence($db, $email, $isOnline);
    respond(['ok' => true, 'data' => ['updated' => true]]);
}

if ($method === 'POST' && $path === 'chats/start') {
    $email = strtolower(requireString($body, 'email'));
    $reportId = trim(requireString($body, 'reportId'));
    if (!campusEmailIsValid($email) || $reportId === '') {
        respond(['ok' => false, 'error' => 'Email atau laporan tidak valid.'], 422);
    }

    try {
        $db->begin_transaction();
        $reportStatement = $db->prepare(
            'SELECT user_email FROM reports WHERE id = ? LIMIT 1 FOR UPDATE',
        );
        $reportStatement->bind_param('s', $reportId);
        $reportStatement->execute();
        $report = $reportStatement->get_result()->fetch_assoc();
        $reportStatement->close();
        if ($report === null || empty($report['user_email'])) {
            $db->rollback();
            respond(['ok' => false, 'error' => 'Laporan tidak ditemukan atau belum memiliki pemilik.'], 404);
        }
        $ownerEmail = strtolower((string) $report['user_email']);
        if ($ownerEmail === $email) {
            $db->rollback();
            respond(['ok' => false, 'error' => 'Anda tidak dapat memulai chat dengan akun sendiri.'], 422);
        }

        $chatLookup = $db->prepare(
            'SELECT c.id
             FROM chats c
             INNER JOIN chat_members cm ON cm.chat_id = c.id AND cm.email = ?
             WHERE c.barang_id = ?
             ORDER BY c.updated_at DESC LIMIT 1',
        );
        $chatLookup->bind_param('ss', $email, $reportId);
        $chatLookup->execute();
        $chatRow = $chatLookup->get_result()->fetch_assoc();
        $chatLookup->close();

        if ($chatRow === null) {
            $chatId = 'chat_' . bin2hex(random_bytes(16));
            $createChat = $db->prepare(
                'INSERT INTO chats (id, barang_id, owner_email) VALUES (?, ?, ?)',
            );
            $createChat->bind_param('sss', $chatId, $reportId, $ownerEmail);
            $createChat->execute();
            $createChat->close();
        } else {
            $chatId = (string) $chatRow['id'];
        }

        $memberStatement = $db->prepare(
            'INSERT IGNORE INTO chat_members (chat_id, email, last_read_at)
             VALUES (?, ?, UTC_TIMESTAMP(6))',
        );
        $memberStatement->bind_param('ss', $chatId, $ownerEmail);
        $memberStatement->execute();
        $memberStatement->bind_param('ss', $chatId, $email);
        $memberStatement->execute();
        $memberStatement->close();
        $db->commit();

        respond(['ok' => true, 'data' => ['chatId' => $chatId]]);
    } catch (Throwable $error) {
        $db->rollback();
        respond(['ok' => false, 'error' => 'Percakapan gagal dibuat.'], 500);
    }
}

if ($method === 'POST' && $path === 'messages/send') {
    $email = strtolower(requireString($body, 'email'));
    $chatId = trim(requireString($body, 'chatId'));
    $text = trim(requireString($body, 'text'));
    if (!campusEmailIsValid($email) || $chatId === '' || $text === '') {
        respond(['ok' => false, 'error' => 'Pesan atau identitas pengirim tidak valid.'], 422);
    }

    $membership = $db->prepare(
        'SELECT c.id
         FROM chats c
         INNER JOIN chat_members cm ON cm.chat_id = c.id AND cm.email = ?
         WHERE c.id = ? LIMIT 1',
    );
    $membership->bind_param('ss', $email, $chatId);
    $membership->execute();
    $member = $membership->get_result()->fetch_assoc();
    $membership->close();
    if ($member === null) {
        respond(['ok' => false, 'error' => 'Anda bukan anggota percakapan ini.'], 403);
    }

    $userStatement = $db->prepare('SELECT nama FROM users WHERE email = ? LIMIT 1');
    $userStatement->bind_param('s', $email);
    $userStatement->execute();
    $user = $userStatement->get_result()->fetch_assoc();
    $userStatement->close();
    if ($user === null) {
        respond(['ok' => false, 'error' => 'Akun pengirim tidak ditemukan.'], 404);
    }
    setPresence($db, $email, true);

    try {
        $db->begin_transaction();
        $senderName = (string) $user['nama'];
        $insertMessage = $db->prepare(
            'INSERT INTO messages (chat_id, pengirim, pengirim_email, teks, waktu, is_me)
             VALUES (?, ?, ?, ?, UTC_TIMESTAMP(6), 1)',
        );
        $insertMessage->bind_param('ssss', $chatId, $senderName, $email, $text);
        $insertMessage->execute();
        $messageId = $db->insert_id;
        $insertMessage->close();

        $updateChat = $db->prepare('UPDATE chats SET updated_at = NOW() WHERE id = ?');
        $updateChat->bind_param('s', $chatId);
        $updateChat->execute();
        $updateChat->close();

        $recipientStatement = $db->prepare(
            'SELECT email FROM chat_members WHERE chat_id = ? AND email <> ?',
        );
        $recipientStatement->bind_param('ss', $chatId, $email);
        $recipientStatement->execute();
        $recipients = $recipientStatement->get_result();
        $notification = $db->prepare(
            'INSERT INTO notifications
              (notification_key, email, chat_id, title, message, waktu, is_read)
             VALUES (?, ?, ?, ?, ?, UTC_TIMESTAMP(6), 0)',
        );
        $title = 'Pesan baru';
        $noticeText = $senderName . ': ' . $text;
        while ($recipient = $recipients->fetch_assoc()) {
            $recipientEmail = strtolower((string) $recipient['email']);
            $notificationKey = hash('sha256', $chatId . '|' . $messageId . '|' . $recipientEmail);
            $notification->bind_param(
                'sssss',
                $notificationKey,
                $recipientEmail,
                $chatId,
                $title,
                $noticeText,
            );
            $notification->execute();
        }
        $notification->close();
        $recipientStatement->close();
        $db->commit();

        respond(['ok' => true, 'data' => ['messageId' => $messageId]]);
    } catch (Throwable $error) {
        $db->rollback();
        respond(['ok' => false, 'error' => 'Pesan gagal disimpan.'], 500);
    }
}

if ($method === 'POST' && $path === 'chats/read') {
    $email = strtolower(requireString($body, 'email'));
    $chatId = trim(requireString($body, 'chatId'));
    if (!campusEmailIsValid($email) || $chatId === '') {
        respond(['ok' => false, 'error' => 'Identitas percakapan tidak valid.'], 422);
    }
    $membershipStatement = $db->prepare(
        'SELECT 1 FROM chat_members WHERE chat_id = ? AND email = ? LIMIT 1',
    );
    $membershipStatement->bind_param('ss', $chatId, $email);
    $membershipStatement->execute();
    $isMember = $membershipStatement->get_result()->num_rows > 0;
    $membershipStatement->close();
    if (!$isMember) {
        respond(['ok' => false, 'error' => 'Anda bukan anggota percakapan ini.'], 403);
    }
    $readStatement = $db->prepare(
        'UPDATE chat_members SET last_read_at = UTC_TIMESTAMP(6) WHERE chat_id = ? AND email = ?',
    );
    $readStatement->bind_param('ss', $chatId, $email);
    $readStatement->execute();
    $readStatement->close();
    $notificationStatement = $db->prepare(
        'UPDATE notifications SET is_read = 1 WHERE email = ? AND chat_id = ?',
    );
    $notificationStatement->bind_param('ss', $email, $chatId);
    $notificationStatement->execute();
    $notificationStatement->close();
    respond(['ok' => true, 'data' => ['read' => true]]);
}

if ($method === 'POST' && $path === 'notifications/read-all') {
    $email = strtolower(requireString($body, 'email'));
    if (!campusEmailIsValid($email)) {
        respond(['ok' => false, 'error' => 'Email kampus tidak valid.'], 422);
    }
    $statement = $db->prepare('UPDATE notifications SET is_read = 1 WHERE email = ?');
    $statement->bind_param('s', $email);
    $statement->execute();
    $statement->close();
    respond(['ok' => true, 'data' => ['read' => true]]);
}

if ($method === 'POST' && $path === 'auth/admin-login') {
    $email = strtolower(requireString($body, 'email'));
    $password = requireString($body, 'password');
    $admin = $config['admin'];

    if (!hash_equals(strtolower($admin['email']), $email) ||
        !hash_equals($admin['password'], $password)) {
        respond(['ok' => false, 'error' => 'Email atau password admin salah.'], 401);
    }

    $expires = time() + 3600;
    respond([
        'ok' => true,
        'data' => [
            'email' => $admin['email'],
            'nama' => $admin['name'],
            'role' => 'admin',
            'token' => createAdminToken($admin['email'], $admin['secret'], $expires),
        ],
    ]);
}

if ($method === 'DELETE' && $path === 'reports') {
    $email = strtolower(trim((string) ($_GET['email'] ?? '')));
    $reportId = trim((string) ($_GET['id'] ?? ''));

    if (!campusEmailIsValid($email)) {
        respond(['ok' => false, 'error' => 'Email kampus tidak valid.'], 422);
    }
    if ($reportId === '') {
        respond(['ok' => false, 'error' => 'ID laporan wajib diisi.'], 422);
    }

    $ownerStatement = $db->prepare(
        'SELECT user_email FROM reports WHERE id = ? LIMIT 1',
    );
    $ownerStatement->bind_param('s', $reportId);
    $ownerStatement->execute();
    $owner = $ownerStatement->get_result()->fetch_assoc();
    $ownerStatement->close();

    if ($owner === null) {
        respond(['ok' => false, 'error' => 'Laporan tidak ditemukan.'], 404);
    }
    if (strtolower((string) $owner['user_email']) !== $email) {
        respond(['ok' => false, 'error' => 'Anda hanya dapat menghapus laporan milik sendiri.'], 403);
    }

    $deleteStatement = $db->prepare(
        'DELETE FROM reports WHERE id = ? AND user_email = ?',
    );
    $deleteStatement->bind_param('ss', $reportId, $email);
    $deleteStatement->execute();
    $deleted = $deleteStatement->affected_rows > 0;
    $deleteStatement->close();

    respond([
        'ok' => $deleted,
        'data' => ['deleted' => $deleted],
    ], $deleted ? 200 : 404);
}

if ($path !== 'sync' && $path !== 'admin/sync') {
    respond(['ok' => false, 'error' => 'Endpoint tidak ditemukan.'], 404);
}

$isAdminRequest = $path === 'admin/sync';
if ($isAdminRequest) {
    if ($method !== 'GET') {
        respond(['ok' => false, 'error' => 'Method tidak didukung.'], 405);
    }
    $admin = $config['admin'];
    $adminToken = (string) ($_SERVER['HTTP_X_ADMIN_TOKEN'] ?? '');
    if (!adminTokenIsValid($adminToken, $admin['email'], $admin['secret'])) {
        respond(['ok' => false, 'error' => 'Sesi admin tidak valid atau sudah kedaluwarsa.'], 401);
    }
    $email = strtolower($admin['email']);
} else {
    $email = strtolower(trim((string) ($body['email'] ?? $_GET['email'] ?? '')));
    if (!campusEmailIsValid($email)) {
        respond(['ok' => false, 'error' => 'Email kampus tidak valid.'], 422);
    }
}

if ($method === 'GET') {
    $reports = [];
    $reportResult = $db->query(
        'SELECT id, nama, lokasi, deskripsi, jenis, pelapor, kontak,
                tanggal, foto, status, user_email
         FROM reports
         ORDER BY tanggal DESC',
    );
    while ($row = $reportResult->fetch_assoc()) {
        $row['tanggal'] = isoDate($row['tanggal']);
        $row['ownerEmail'] = strtolower((string) $row['user_email']);
        unset($row['user_email']);
        $reports[] = $row;
    }

    $chats = [];
    $adminEmail = strtolower($config['admin']['email']);
    $chatQuery = $isAdminRequest
        ? 'SELECT c.id AS chat_id, c.is_online, c.last_seen, c.unread_count,
                  CASE WHEN p.is_online = 1 AND p.last_seen >= DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 SECOND)
                       THEN 1 ELSE 0 END AS peer_online,
                  p.last_seen AS peer_last_seen,
                  (SELECT COUNT(*) FROM messages unread_message
                   INNER JOIN chat_members unread_member
                     ON unread_member.chat_id = unread_message.chat_id
                    AND unread_member.email = ?
                   WHERE unread_message.chat_id = c.id
                     AND unread_message.pengirim_email <> ?
                     AND unread_message.waktu > COALESCE(unread_member.last_read_at, unread_member.joined_at)
                  ) AS user_unread_count,
                  r.id AS report_id, r.nama, r.lokasi, r.deskripsi, r.jenis,
                  r.pelapor, r.kontak, r.tanggal, r.foto, r.status,
                  r.user_email AS report_owner_email,
                  owner_user.nama AS peer_name
           FROM chats c
           INNER JOIN reports r ON r.id = c.barang_id
           LEFT JOIN user_presence p ON p.email = c.owner_email
           LEFT JOIN users owner_user ON owner_user.email = c.owner_email
           ORDER BY c.updated_at DESC'
        : 'SELECT c.id AS chat_id, c.is_online, c.last_seen, c.unread_count,
                  CASE WHEN peer_presence.is_online = 1 AND peer_presence.last_seen >= DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 SECOND)
                       THEN 1 ELSE 0 END AS peer_online,
                  peer_presence.last_seen AS peer_last_seen,
                  (SELECT COUNT(*) FROM messages unread_message
                   WHERE unread_message.chat_id = c.id
                     AND unread_message.pengirim_email <> member.email
                     AND unread_message.waktu > COALESCE(member.last_read_at, member.joined_at)
                  ) AS user_unread_count,
                  r.id AS report_id, r.nama, r.lokasi, r.deskripsi, r.jenis,
                  r.pelapor, r.kontak, r.tanggal, r.foto, r.status,
                  r.user_email AS report_owner_email,
                  peer_user.nama AS peer_name
           FROM chats c
           INNER JOIN reports r ON r.id = c.barang_id
           INNER JOIN chat_members member
             ON member.chat_id = c.id AND member.email = ?
           LEFT JOIN chat_members peer
             ON peer.chat_id = c.id AND peer.email <> member.email
            AND peer.email = (SELECT preferred_peer.email FROM chat_members preferred_peer
                              WHERE preferred_peer.chat_id = c.id
                                AND preferred_peer.email <> member.email
                              ORDER BY (preferred_peer.email = r.user_email) DESC,
                                       preferred_peer.joined_at ASC LIMIT 1)
           LEFT JOIN user_presence peer_presence
             ON peer_presence.email = peer.email
           LEFT JOIN users peer_user ON peer_user.email = peer.email
           ORDER BY c.updated_at DESC';
    $chatStatement = $db->prepare($chatQuery);
    if ($isAdminRequest) {
        $chatStatement->bind_param('ss', $email, $email);
    } else {
        $chatStatement->bind_param('s', $email);
    }
    $chatStatement->execute();
    $chatRows = $chatStatement->get_result();

    $messageStatement = $db->prepare(
        'SELECT pengirim, pengirim_email, teks, waktu, is_me
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
            $senderEmail = strtolower((string) ($message['pengirim_email'] ?? ''));
            $messages[] = [
                'pengirim' => $message['pengirim'],
                'teks' => $message['teks'],
                'waktu' => isoDate($message['waktu']),
                'pengirimEmail' => $senderEmail,
                'isMe' => $senderEmail !== ''
                    ? $senderEmail === $email
                    : (bool) $message['is_me'],
            ];
        }

        $chats[] = [
            'id' => $row['chat_id'],
            'peerName' => $row['peer_name'],
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
                'ownerEmail' => strtolower((string) ($row['report_owner_email'] ?? '')),
            ],
            'pesanList' => $messages,
            'isOnline' => (bool) ($row['peer_online'] ?? $row['is_online']),
            'lastSeen' => isoDate($row['peer_last_seen'] ?? $row['last_seen']),
            'unreadCount' => (int) $row['user_unread_count'],
        ];
    }

    $messageStatement->close();
    $chatStatement->close();

    $notifications = [];
    $notificationStatement = $db->prepare(
        'SELECT title, message, waktu, is_read, chat_id
         FROM notifications
         WHERE (? = ? OR email = ?)
         ORDER BY waktu DESC',
    );
    $notificationStatement->bind_param('sss', $email, $adminEmail, $email);
    $notificationStatement->execute();
    $notificationRows = $notificationStatement->get_result();

    while ($notification = $notificationRows->fetch_assoc()) {
        $notifications[] = [
            'title' => $notification['title'],
            'message' => $notification['message'],
            'waktu' => isoDate($notification['waktu']),
            'isRead' => (bool) $notification['is_read'],
            'chatId' => $notification['chat_id'],
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
$identityError = ensureUser($db, $email, $nim, $nama);
if ($identityError !== null) {
    respond(['ok' => false, 'error' => $identityError], 409);
}
setPresence($db, $email, true);

$reports = is_array($body['reports'] ?? null) ? $body['reports'] : [];
// Chat dan notifikasi ditulis melalui endpoint khusus agar snapshot client
// tidak pernah menghapus atau menimpa pesan yang dikirim akun lain.
$chats = [];
$notifications = [];

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
           status = VALUES(status)',
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
        'INSERT INTO messages
          (chat_id, pengirim, pengirim_email, teks, waktu, is_me)
         VALUES (?, ?, ?, ?, ?, ?)',
    );
    $memberStatement = $db->prepare(
        'INSERT IGNORE INTO chat_members (chat_id, email) VALUES (?, ?)',
    );
    $reportOwnerStatement = $db->prepare(
        'SELECT user_email FROM reports WHERE id = ? LIMIT 1',
    );
    $peerStatement = $db->prepare(
        'SELECT email FROM chat_members WHERE chat_id = ? AND email <> ?',
    );
    $messageNotificationStatement = $db->prepare(
        'INSERT INTO notifications
          (notification_key, email, title, message, waktu, is_read)
         VALUES (?, ?, ?, ?, ?, 0)
         ON DUPLICATE KEY UPDATE
           title = VALUES(title), message = VALUES(message), waktu = VALUES(waktu)',
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
        $reportOwnerEmail = $email;
        $reportOwnerStatement->bind_param('s', $barangId);
        $reportOwnerStatement->execute();
        $reportOwnerRow = $reportOwnerStatement->get_result()->fetch_assoc();
        if (!empty($reportOwnerRow['user_email'])) {
            $reportOwnerEmail = strtolower((string) $reportOwnerRow['user_email']);
        }

        $chatStatement->bind_param(
            'sssisi',
            $chatId,
            $barangId,
            $reportOwnerEmail,
            $online,
            $lastSeen,
            $unread,
        );
        $chatStatement->execute();

        $memberStatement->bind_param('ss', $chatId, $email);
        $memberStatement->execute();
        if ($reportOwnerEmail !== '') {
            $memberStatement->bind_param('ss', $chatId, $reportOwnerEmail);
            $memberStatement->execute();
        }

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
            $senderEmail = strtolower((string) ($message['pengirimEmail'] ?? ''));
            if ($senderEmail === '') {
                $senderEmail = !empty($message['isMe']) ? $email : $reportOwnerEmail;
            }
            $text = (string) ($message['teks'] ?? '');
            $time = databaseDate($message['waktu'] ?? null);
            $isMe = !empty($message['isMe']) ? 1 : 0;

            $messageStatement->bind_param(
                'sssssi',
                $chatId,
                $sender,
                $senderEmail,
                $text,
                $time,
                $isMe,
            );
            $messageStatement->execute();

            $peerStatement->bind_param('ss', $chatId, $senderEmail);
            $peerStatement->execute();
            $peerRows = $peerStatement->get_result();
            while ($peer = $peerRows->fetch_assoc()) {
                $peerEmail = strtolower((string) $peer['email']);
                $notificationKey = hash(
                    'sha256',
                    implode('|', [$chatId, $senderEmail, $text, $time, $peerEmail]),
                );
                $notificationTitle = 'Pesan baru';
                $notificationMessage = $sender . ': ' . $text;
                $messageNotificationStatement->bind_param(
                    'sssss',
                    $notificationKey,
                    $peerEmail,
                    $notificationTitle,
                    $notificationMessage,
                    $time,
                );
                $messageNotificationStatement->execute();
            }
        }
    }

    $chatStatement->close();
    $deleteMessageStatement->close();
    $messageStatement->close();
    $memberStatement->close();
    $reportOwnerStatement->close();
    $peerStatement->close();
    $messageNotificationStatement->close();

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
