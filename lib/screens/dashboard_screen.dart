part of '../main.dart';

class DashboardScreen extends StatefulWidget {
  final String nim;
  final String nama;
  final String email;

  const DashboardScreen(
      {super.key, required this.nim, required this.nama, required this.email});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  RingkasanDashboard? _ringkasan;
  bool _memuat = true;
  bool _gagalMuat = false;

  @override
  void initState() {
    super.initState();
    unawaited(_muatRingkasan());
  }

  Future<void> _muatRingkasan() async {
    try {
      final snapshot = await AppDataRepository().load(email: widget.email);
      if (!mounted) return;
      setState(() {
        _ringkasan = RingkasanDashboard.dariSnapshot(snapshot);
        _memuat = false;
        _gagalMuat = false;
      });
    } catch (error) {
      debugPrint('Gagal memuat ringkasan dashboard: $error');
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _gagalMuat = true;
      });
    }
  }

  Future<void> _segarkan() async {
    setState(() => _memuat = true);
    await _muatRingkasan();
  }

  void _masukAplikasi({int initialIndex = 0}) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => MainNavigationScreen(
                nim: widget.nim,
                nama: widget.nama,
                email: widget.email,
                initialIndex: initialIndex)));
  }

  String get _teksTemuanAktif {
    if (_memuat) return '...';
    final ringkasan = _ringkasan;
    if (ringkasan == null) return '—';
    return ringkasan.temuanAktif.toString().padLeft(2, '0');
  }

  String get _teksPesanBaru {
    if (_memuat) return '...';
    final ringkasan = _ringkasan;
    if (ringkasan == null) return '—';
    return ringkasan.pesanBaru.toString().padLeft(2, '0');
  }

  String get _judulRingkasan {
    if (_memuat) return 'Memuat ringkasan…';
    if (_gagalMuat) return 'Ringkasan belum tersedia';
    return _ringkasan?.judulPesan ?? 'Belum ada aktivitas';
  }

  String get _isiRingkasan {
    if (_memuat) return 'Menghubungkan ke server kampus.';
    if (_gagalMuat) return 'Server belum dapat dijangkau. Tarik ke bawah untuk mencoba lagi.';
    return _ringkasan?.isiPesan ?? 'Aktivitas klaim akan muncul di sini.';
  }

  @override
  Widget build(BuildContext context) {
    final dariCache = _ringkasan?.dariCache ?? false;
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
            padding: EdgeInsets.all(12), child: UinLogo(size: 28)),
        title: const Text('Dashboard'),
        actions: [
          Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: UINColors.mint,
                  borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [
                Icon(Icons.verified_outlined,
                    color: UINColors.primary, size: 15),
                SizedBox(width: 4),
                Text('Terverifikasi',
                    style: TextStyle(
                        color: UINColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800))
              ]))
        ],
      ),
      body: ResponsivePage(
        maxWidth: 1650,
        child: RefreshIndicator(
          onRefresh: _segarkan,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
            children: [
              const Text("Assalamu'alaikum,",
                  style: TextStyle(
                      color: UINColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(widget.nama,
                  style: const TextStyle(
                      color: UINColors.deep,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(widget.email,
                  style:
                      const TextStyle(color: UINColors.muted, fontSize: 12)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [UINColors.deep, UINColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                          color: UINColors.primary.withValues(alpha: .2),
                          blurRadius: 18,
                          offset: const Offset(0, 9))
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Expanded(
                            child: Text('Pusat aktivitas kampusmu',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900))),
                        Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                                color: UINColors.gold.withValues(alpha: .2),
                                borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.auto_awesome,
                                color: UINColors.gold, size: 24))
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          'Satu ruang untuk membantu barang kembali kepada pemiliknya.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: .75),
                              fontSize: 12,
                              height: 1.4)),
                      const SizedBox(height: 20),
                      Row(children: [
                        _DashboardMetric(
                            value: _teksTemuanAktif, label: 'Temuan aktif'),
                        const SizedBox(width: 10),
                        _DashboardMetric(
                            value: _teksPesanBaru, label: 'Pesan baru'),
                        const SizedBox(width: 10),
                        _DashboardMetric(
                            value: widget.nim, label: 'NIM terdaftar')
                      ])
                    ]),
              ),
              const SizedBox(height: 24),
              const Text('Akses cepat',
                  style: TextStyle(
                      color: UINColors.deep,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _DashboardAction(
                        icon: Icons.explore_outlined,
                        title: 'Jelajah barang',
                        subtitle: 'Lihat temuan terbaru',
                        color: UINColors.mint,
                        onTap: () => _masukAplikasi())),
                const SizedBox(width: 12),
                Expanded(
                    child: _DashboardAction(
                        icon: Icons.add_a_photo_outlined,
                        title: 'Buat laporan',
                        subtitle: 'Bantu warga kampus',
                        color: const Color(0xFFFFEEE9),
                        onTap: () => _masukAplikasi(initialIndex: 1)))
              ]),
              const SizedBox(height: 24),
              const Text('Ringkasan hari ini',
                  style: TextStyle(
                      color: UINColors.deep,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Card(
                  child: Column(children: [
                ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: UINColors.mint,
                        child: Icon(Icons.chat_bubble_outline,
                            color: UINColors.primary)),
                    title: Text(_judulRingkasan,
                        style: const TextStyle(
                            color: UINColors.deep,
                            fontWeight: FontWeight.w800)),
                    subtitle: Text(_isiRingkasan)),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const ListTile(
                    leading: CircleAvatar(
                        backgroundColor: Color(0xFFFFF3D4),
                        child: Icon(Icons.shield_outlined,
                            color: UINColors.gold)),
                    title: Text('Akun terlindungi',
                        style: TextStyle(
                            color: UINColors.deep,
                            fontWeight: FontWeight.w800)),
                    subtitle:
                        Text('Email resmi UIN Malang berhasil diverifikasi.'))
              ])),
              if (dariCache) ...[
                const SizedBox(height: 10),
                const Text(
                    'Menampilkan data tersimpan karena server belum merespons.',
                    style: TextStyle(color: UINColors.muted, fontSize: 11))
              ],
              const SizedBox(height: 22),
              SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                      onPressed: () => _masukAplikasi(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('MASUK KE RUANG TEMU',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      style: FilledButton.styleFrom(
                          backgroundColor: UINColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)))))
            ],
          ),
        ),
      ),
    );
  }
}

/// Angka dan ringkasan nyata untuk dashboard, dihitung dari data server.
class RingkasanDashboard {
  final int temuanAktif;
  final int pesanBaru;
  final String judulPesan;
  final String isiPesan;
  final bool dariCache;

  const RingkasanDashboard({
    required this.temuanAktif,
    required this.pesanBaru,
    required this.judulPesan,
    required this.isiPesan,
    this.dariCache = false,
  });

  factory RingkasanDashboard.dariSnapshot(LocalDataSnapshot snapshot) {
    final temuanAktif = snapshot.reports
        .where((item) =>
            item.jenis == JenisLaporan.ditemukan &&
            item.status != StatusBarang.selesai)
        .length;
    final pesanBaru = snapshot.chats
        .fold<int>(0, (total, sesi) => total + sesi.unreadCount);
    final belumDibaca =
        snapshot.notifications.where((item) => !item.isRead).toList();

    if (belumDibaca.isNotEmpty) {
      return RingkasanDashboard(
        temuanAktif: temuanAktif,
        pesanBaru: pesanBaru,
        judulPesan: belumDibaca.first.title,
        isiPesan: belumDibaca.first.message,
        dariCache: snapshot.fromCache,
      );
    }
    if (pesanBaru > 0) {
      return RingkasanDashboard(
        temuanAktif: temuanAktif,
        pesanBaru: pesanBaru,
        judulPesan: 'Ada $pesanBaru pesan yang menunggu',
        isiPesan: 'Buka tab Chat untuk meninjau percakapan klaim.',
        dariCache: snapshot.fromCache,
      );
    }
    return RingkasanDashboard(
      temuanAktif: temuanAktif,
      pesanBaru: 0,
      judulPesan: 'Tidak ada pesan baru',
      isiPesan: 'Semua percakapan klaim sudah dibaca.',
      dariCache: snapshot.fromCache,
    );
  }
}
