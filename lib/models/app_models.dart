part of '../../main.dart';

enum JenisLaporan { ditemukan, hilang }

enum StatusBarang { belumDiklaim, prosesKlaim, selesai }

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
      status: StatusBarang.values.firstWhere(
        (item) => item.name == raw['status'],
        orElse: () => StatusBarang.belumDiklaim,
      ),
    );
  }
}

class PesanChat {
  final String pengirim;
  final String? pengirimEmail;
  final String teks;
  final DateTime waktu;
  final bool isMe;

  PesanChat(
      {required this.pengirim,
      this.pengirimEmail,
      required this.teks,
      required this.waktu,
      required this.isMe});

  Map<String, dynamic> toMap() => {
        'pengirim': pengirim,
        'pengirimEmail': pengirimEmail,
        'teks': teks,
        'waktu': waktu.toIso8601String(),
        'isMe': isMe,
      };

  static PesanChat fromMap(Map<dynamic, dynamic> raw) => PesanChat(
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
