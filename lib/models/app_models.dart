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
      status: StatusBarang.values.firstWhere(
        (item) => item.name == raw['status'],
        orElse: () => StatusBarang.belumDiklaim,
      ),
    );
  }
}

class PesanChat {
  final String pengirim;
  final String teks;
  final DateTime waktu;
  final bool isMe;

  PesanChat(
      {required this.pengirim,
      required this.teks,
      required this.waktu,
      required this.isMe});

  Map<String, dynamic> toMap() => {
        'pengirim': pengirim,
        'teks': teks,
        'waktu': waktu.toIso8601String(),
        'isMe': isMe,
      };

  static PesanChat fromMap(Map<dynamic, dynamic> raw) => PesanChat(
        pengirim: '${raw['pengirim'] ?? ''}',
        teks: '${raw['teks'] ?? ''}',
        waktu: DateTime.tryParse('${raw['waktu']}') ?? DateTime.now(),
        isMe: raw['isMe'] == true,
      );
}

class SesiChat {
  final String id;
  final BarangItem barang;
  final List<PesanChat> pesanList;
  final bool isOnline;
  final DateTime? lastSeen;
  int unreadCount;

  SesiChat(
      {required this.id,
      required this.barang,
      required this.pesanList,
      this.isOnline = false,
      this.lastSeen,
      this.unreadCount = 0});

  Map<String, dynamic> toMap() => {
        'id': id,
        'barang': barang.toMap(),
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
  bool isRead;

  NotifikasiItem(
      {required this.title,
      required this.message,
      required this.waktu,
      this.isRead = false});

  Map<String, dynamic> toMap() => {
        'title': title,
        'message': message,
        'waktu': waktu.toIso8601String(),
        'isRead': isRead,
      };

  static NotifikasiItem fromMap(Map<dynamic, dynamic> raw) => NotifikasiItem(
        title: '${raw['title'] ?? ''}',
        message: '${raw['message'] ?? ''}',
        waktu: DateTime.tryParse('${raw['waktu']}') ?? DateTime.now(),
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
