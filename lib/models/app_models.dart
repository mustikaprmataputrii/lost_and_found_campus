part of '../../main.dart';

enum JenisLaporan { ditemukan, hilang }

enum StatusBarang { belumDiklaim, prosesKlaim, selesai }

class AuthSession {
  final String email;
  final String nim;
  final String nama;
  final LoginRole role;
  final String? adminToken;

  const AuthSession({
    required this.email,
    required this.nim,
    required this.nama,
    required this.role,
    this.adminToken,
  });

  bool get isAdmin => role == LoginRole.admin;
}

class BarangItem {
  final String id;
  final String nama;
  final String lokasi;
  final String deskripsi;
  final JenisLaporan jenis;
  final String pelapor;
  final String kontak;
  final DateTime tanggal;
  final Uint8List? fotoBytes;
  String? pemilikEmail;
  String? claimantEmail;
  StatusBarang status;

  BarangItem({
    required this.id,
    required this.nama,
    required this.lokasi,
    required this.deskripsi,
    required this.jenis,
    required this.pelapor,
    required this.kontak,
    required this.tanggal,
    this.fotoBytes,
    this.pemilikEmail,
    this.claimantEmail,
    this.status = StatusBarang.belumDiklaim,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'lokasi': lokasi,
        'deskripsi': deskripsi,
        'jenis': jenis.name,
        'pelapor': pelapor,
        'kontak': kontak,
        'tanggal': tanggal.toIso8601String(),
        'foto': fotoBytes == null ? null : base64Encode(fotoBytes!),
        'ownerEmail': pemilikEmail,
        'claimantEmail': claimantEmail,
        'status': status.name,
      };

  static BarangItem fromMap(Map<dynamic, dynamic> raw) {
    final foto = raw['foto'];
    return BarangItem(
      id: '${raw['id'] ?? ''}',
      nama: '${raw['nama'] ?? ''}',
      lokasi: '${raw['lokasi'] ?? ''}',
      deskripsi: '${raw['deskripsi'] ?? ''}',
      jenis: JenisLaporan.values.firstWhere(
        (item) => item.name == raw['jenis'],
        orElse: () => JenisLaporan.ditemukan,
      ),
      pelapor: '${raw['pelapor'] ?? ''}',
      kontak: '${raw['kontak'] ?? ''}',
      tanggal: DateTime.tryParse('${raw['tanggal']}') ?? DateTime.now(),
      fotoBytes: foto is String && foto.isNotEmpty ? base64Decode(foto) : null,
      pemilikEmail: raw['ownerEmail'] == null ? null : '${raw['ownerEmail']}',
      claimantEmail:
          raw['claimantEmail'] == null ? null : '${raw['claimantEmail']}',
      status: StatusBarang.values.firstWhere(
        (item) => item.name == raw['status'],
        orElse: () => StatusBarang.belumDiklaim,
      ),
    );
  }
}

class PendingUpload {
  final String reportId;
  final String email;
  final String nama;
  final BarangItem report;
  final int attempts;
  final DateTime nextAttemptAt;
  final String? lastError;

  const PendingUpload({
    required this.reportId,
    required this.email,
    required this.nama,
    required this.report,
    required this.attempts,
    required this.nextAttemptAt,
    this.lastError,
  });

  PendingUpload copyWith({
    int? attempts,
    DateTime? nextAttemptAt,
    String? lastError,
  }) =>
      PendingUpload(
        reportId: reportId,
        email: email,
        nama: nama,
        report: report,
        attempts: attempts ?? this.attempts,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
        lastError: lastError ?? this.lastError,
      );

  Map<String, dynamic> toMap() => {
        'reportId': reportId,
        'email': email,
        'nama': nama,
        'report': report.toMap(),
        'attempts': attempts,
        'nextAttemptAt': nextAttemptAt.toIso8601String(),
        'lastError': lastError,
      };

  static PendingUpload fromMap(Map<dynamic, dynamic> raw) {
    final reportRaw = raw['report'];
    if (reportRaw is! Map) {
      throw const FormatException('Data antrean upload tidak valid.');
    }
    final report = BarangItem.fromMap(
      Map<dynamic, dynamic>.from(reportRaw),
    );
    return PendingUpload(
      reportId: '${raw['reportId'] ?? report.id}',
      email: '${raw['email'] ?? ''}',
      nama: '${raw['nama'] ?? ''}',
      report: report,
      attempts: (raw['attempts'] as num?)?.toInt() ?? 0,
      nextAttemptAt:
          DateTime.tryParse('${raw['nextAttemptAt']}') ?? DateTime.now(),
      lastError: raw['lastError'] == null ? null : '${raw['lastError']}',
    );
  }
}

class ReportSubmissionResult {
  final bool uploaded;

  const ReportSubmissionResult.uploaded() : uploaded = true;
  const ReportSubmissionResult.queued() : uploaded = false;
}

class ReportDraft {
  final String email;
  final String nama;
  final String lokasi;
  final String deskripsi;
  final String kontak;
  final JenisLaporan jenis;
  final Uint8List? fotoBytes;
  final DateTime updatedAt;

  const ReportDraft({
    required this.email,
    required this.nama,
    required this.lokasi,
    required this.deskripsi,
    required this.kontak,
    required this.jenis,
    this.fotoBytes,
    required this.updatedAt,
  });

  bool get isEmpty =>
      nama.trim().isEmpty &&
      lokasi.trim().isEmpty &&
      deskripsi.trim().isEmpty &&
      kontak.trim().isEmpty &&
      fotoBytes == null;

  Map<String, dynamic> toMap() => {
        'email': email,
        'nama': nama,
        'lokasi': lokasi,
        'deskripsi': deskripsi,
        'kontak': kontak,
        'jenis': jenis.name,
        'foto': fotoBytes == null ? null : base64Encode(fotoBytes!),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static ReportDraft fromMap(Map<dynamic, dynamic> raw) {
    final foto = raw['foto'];
    return ReportDraft(
      email: '${raw['email'] ?? ''}',
      nama: '${raw['nama'] ?? ''}',
      lokasi: '${raw['lokasi'] ?? ''}',
      deskripsi: '${raw['deskripsi'] ?? ''}',
      kontak: '${raw['kontak'] ?? ''}',
      jenis: JenisLaporan.values.firstWhere(
        (item) => item.name == raw['jenis'],
        orElse: () => JenisLaporan.ditemukan,
      ),
      fotoBytes: foto is String && foto.isNotEmpty ? base64Decode(foto) : null,
      updatedAt: DateTime.tryParse('${raw['updatedAt']}') ?? DateTime.now(),
    );
  }
}

class PesanChat {
  final String? id;
  final String pengirim;
  final String? pengirimEmail;
  final String teks;
  final DateTime waktu;
  final bool isMe;

  PesanChat(
      {this.id,
      required this.pengirim,
      this.pengirimEmail,
      required this.teks,
      required this.waktu,
      required this.isMe});

  Map<String, dynamic> toMap() => {
        'id': id,
        'pengirim': pengirim,
        'pengirimEmail': pengirimEmail,
        'teks': teks,
        'waktu': waktu.toIso8601String(),
        'isMe': isMe,
      };

  static PesanChat fromMap(Map<dynamic, dynamic> raw) => PesanChat(
        id: raw['id'] == null ? null : '${raw['id']}',
        pengirim: '${raw['pengirim'] ?? ''}',
        pengirimEmail:
            raw['pengirimEmail'] == null ? null : '${raw['pengirimEmail']}',
        teks: '${raw['teks'] ?? ''}',
        waktu: DateTime.tryParse('${raw['waktu']}') ?? DateTime.now(),
        isMe: raw['isMe'] == true,
      );
}

class SesiChat {
  final String id;
  final BarangItem barang;
  final String? peerName;
  final List<PesanChat> pesanList;
  final bool isOnline;
  final DateTime? lastSeen;
  int unreadCount;

  SesiChat(
      {required this.id,
      required this.barang,
      this.peerName,
      required this.pesanList,
      this.isOnline = false,
      this.lastSeen,
      this.unreadCount = 0});

  Map<String, dynamic> toMap() => {
        'id': id,
        'barang': barang.toMap(),
        'peerName': peerName,
        'pesanList': pesanList.map((pesan) => pesan.toMap()).toList(),
        'isOnline': isOnline,
        'lastSeen': lastSeen?.toIso8601String(),
        'unreadCount': unreadCount,
      };

  static SesiChat fromMap(Map<dynamic, dynamic> raw) {
    final rawMessages = raw['pesanList'];
    return SesiChat(
      id: '${raw['id'] ?? ''}',
      barang:
          BarangItem.fromMap(Map<dynamic, dynamic>.from(raw['barang'] as Map)),
      peerName: raw['peerName'] == null ? null : '${raw['peerName']}',
      pesanList: rawMessages is List
          ? rawMessages
              .map((item) =>
                  PesanChat.fromMap(Map<dynamic, dynamic>.from(item as Map)))
              .toList()
          : [],
      isOnline: raw['isOnline'] == true,
      lastSeen: raw['lastSeen'] == null
          ? null
          : DateTime.tryParse('${raw['lastSeen']}'),
      unreadCount: (raw['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class NotifikasiItem {
  final String title;
  final String message;
  final DateTime waktu;
  final String? chatId;
  bool isRead;

  NotifikasiItem(
      {required this.title,
      required this.message,
      required this.waktu,
      this.chatId,
      this.isRead = false});

  Map<String, dynamic> toMap() => {
        'title': title,
        'message': message,
        'waktu': waktu.toIso8601String(),
        'chatId': chatId,
        'isRead': isRead,
      };

  static NotifikasiItem fromMap(Map<dynamic, dynamic> raw) => NotifikasiItem(
        title: '${raw['title'] ?? ''}',
        message: '${raw['message'] ?? ''}',
        waktu: DateTime.tryParse('${raw['waktu']}') ?? DateTime.now(),
        chatId: raw['chatId'] == null ? null : '${raw['chatId']}',
        isRead: raw['isRead'] == true,
      );
}

class AdminLoginResult {
  final String email;
  final String nama;
  final String token;

  const AdminLoginResult({
    required this.email,
    required this.nama,
    required this.token,
  });

  factory AdminLoginResult.fromMap(Map<String, dynamic> raw) {
    final data = Map<String, dynamic>.from(raw['data'] as Map);
    return AdminLoginResult(
      email: '${data['email'] ?? ''}',
      nama: '${data['nama'] ?? 'Administrator'}',
      token: '${data['token'] ?? ''}',
    );
  }
}

class AdminUser {
  final String nim;
  final String email;
  final String nama;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  const AdminUser({
    required this.nim,
    required this.email,
    required this.nama,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
  });

  factory AdminUser.fromMap(Map<dynamic, dynamic> raw) => AdminUser(
        nim: '${raw['nim'] ?? ''}',
        email: '${raw['email'] ?? ''}',
        nama: '${raw['nama'] ?? ''}',
        isOnline: raw['isOnline'] == true || raw['isOnline'] == 1,
        lastSeen: raw['lastSeen'] == null
            ? null
            : DateTime.tryParse('${raw['lastSeen']}'),
        createdAt: raw['createdAt'] == null
            ? null
            : DateTime.tryParse('${raw['createdAt']}'),
      );
}
