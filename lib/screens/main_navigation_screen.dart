part of '../main.dart';

class MainNavigationScreen extends StatefulWidget {
  final String nim;
  final String nama;
  final String email;
  final int initialIndex;
  const MainNavigationScreen(
      {super.key,
      required this.nim,
      required this.nama,
      required this.email,
      this.initialIndex = 0});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  late int _currentIndex = widget.initialIndex;
  int _detikSesi = 0;
  String _appStateStr = 'resumed';
  Timer? _timer;
  Timer? _syncTimer;

  final List<BarangItem> _daftarBarang = [];
  final List<SesiChat> _daftarSesiChat = [];
  final List<NotifikasiItem> _notifikasi = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _muatWaktuSesi();
    _mulaiTimer();
    _siapkanDataAwal();
  }

  Future<void> _siapkanDataAwal() async {
    unawaited(AppDataRepository()
        .updatePresence(email: widget.email, isOnline: true));
    await _sinkronkanDariServer(showPopup: false);
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_sinkronkanDariServer());
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted && _daftarSesiChat.isNotEmpty) {
      final sesi = _daftarSesiChat.first;
      if (sesi.unreadCount > 0 && sesi.pesanList.isNotEmpty) {
        _tampilkanPopupPesan(sesi, sesi.pesanList.last);
      }
    }
  }

  Future<void> _sinkronkanDariServer({bool showPopup = true}) async {
    try {
      final snapshot = await AppDataRepository().load(email: widget.email);
      if (!mounted) return;

      final oldChats = {
        for (final sesi in _daftarSesiChat) sesi.id: sesi,
      };
      final incoming = <(SesiChat, PesanChat)>[];
      for (final sesi in snapshot.chats) {
        final previous = oldChats[sesi.id];
        if (previous == null) continue;
        final previousMessages =
            previous.pesanList.map(_signaturePesan).toSet();
        for (final pesan in sesi.pesanList) {
          if (!pesan.isMe &&
              !previousMessages.contains(_signaturePesan(pesan))) {
            incoming.add((sesi, pesan));
          }
        }
      }

      setState(() {
        _daftarBarang
          ..clear()
          ..addAll(snapshot.reports);
        _daftarSesiChat
          ..clear()
          ..addAll(snapshot.chats);
        _notifikasi
          ..clear()
          ..addAll(snapshot.notifications);
      });

      if (showPopup && incoming.isNotEmpty && mounted) {
        final received = incoming.last;
        final currentSession = _daftarSesiChat.firstWhere(
          (item) => item.id == received.$1.id,
          orElse: () => received.$1,
        );
        _tampilkanPopupPesan(currentSession, received.$2);
      }
    } catch (_) {
      // Data yang sedang tampil dipertahankan jika server sementara offline.
    }
  }

  String _signaturePesan(PesanChat pesan) =>
      '${pesan.pengirimEmail}|${pesan.pengirim}|${pesan.teks}|${pesan.waktu.toIso8601String()}';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    setState(() => _appStateStr = state.name);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _timer?.cancel();
      _simpanWaktuSesi();
      unawaited(AppDataRepository()
          .updatePresence(email: widget.email, isOnline: false));
    } else if (state == AppLifecycleState.resumed) {
      _mulaiTimer();
      unawaited(AppDataRepository()
          .updatePresence(email: widget.email, isOnline: true));
    }
  }

  void _mulaiTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _detikSesi++);
    });
  }

  Future<void> _muatWaktuSesi() async {
    final seconds = await SessionService().loadSeconds();
    if (mounted) {
      setState(() => _detikSesi = seconds ?? 0);
    }
  }

  Future<void> _simpanWaktuSesi() async {
    await SessionService().saveSeconds(_detikSesi);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  int get _totalUnreadChat =>
      _daftarSesiChat.fold(0, (total, sesi) => total + sesi.unreadCount);
  int get _totalUnreadNotifikasi =>
      _notifikasi.where((item) => !item.isRead).length;
  void _tambahBarang(BarangItem item) {
    item.pemilikEmail = widget.email;
    setState(() => _daftarBarang.insert(0, item));
    unawaited(_simpanData());
  }

  Future<void> _hapusBarang(BarangItem item) async {
    await AppDataRepository()
        .deleteReport(email: widget.email, reportId: item.id);
    if (!mounted) return;
    setState(() => _daftarBarang.removeWhere((report) => report.id == item.id));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Laporan berhasil dihapus.'),
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _simpanData() {
    for (final sesi in _daftarSesiChat) {
      for (final report in _daftarBarang) {
        if (report.id == sesi.barang.id) {
          report.status = sesi.barang.status;
          break;
        }
      }
    }
    return AppDataRepository().saveAll(
      email: widget.email,
      nama: widget.nama,
      reports: _daftarBarang,
      chats: _daftarSesiChat,
      notifications: _notifikasi,
    );
  }

  void _tampilkanPopupPesan(SesiChat sesi, PesanChat pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: UINColors.deep,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Row(children: [
            const CircleAvatar(
                backgroundColor: UINColors.gold,
                child: Icon(Icons.chat_bubble_outline,
                    color: UINColors.deep, size: 19)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text('Pesan baru • ${sesi.barang.nama}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(pesan.teks,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12))
                ]))
          ]),
          action: SnackBarAction(
              label: 'BUKA',
              textColor: UINColors.gold,
              onPressed: () => _bukaChat(sesi))));
  }

  // Satu pintu untuk setiap event pesan masuk dari backend/realtime service.
  void terimaPesanMasuk(SesiChat sesi, String teks, {String? pengirim}) {
    final pesan = PesanChat(
        pengirim: pengirim ?? sesi.barang.pelapor,
        teks: teks,
        waktu: DateTime.now(),
        isMe: false);
    setState(() {
      sesi.pesanList.add(pesan);
      sesi.unreadCount++;
      _notifikasi.insert(
          0,
          NotifikasiItem(
              title: 'Pesan baru',
              message: '${pesan.pengirim}: ${pesan.teks}',
              waktu: pesan.waktu));
    });
    unawaited(_simpanData());
    _tampilkanPopupPesan(sesi, pesan);
  }

  void _bukaChatDariBarang(BarangItem item) {
    var index = _daftarSesiChat.indexWhere((sesi) => sesi.barang.id == item.id);
    if (index < 0) {
      _daftarSesiChat.add(SesiChat(
          id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
          barang: item,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 12)),
          pesanList: [
            PesanChat(
                pengirim: 'Sistem TEMU',
                teks: 'Sesi konsultasi klaim barang telah dibuka.',
                waktu: DateTime.now(),
                isMe: false)
          ]));
      index = _daftarSesiChat.length - 1;
    }
    _bukaChat(_daftarSesiChat[index]);
  }

  void _bukaChat(SesiChat sesi) {
    setState(() {
      sesi.unreadCount = 0;
      for (final item in _notifikasi) {
        if (item.title == 'Pesan baru' &&
            item.message.contains(sesi.barang.nama)) {
          item.isRead = true;
        }
      }
    });
    unawaited(_simpanData());
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RoomChatScreen(
                sesi: sesi,
                currentUserName: widget.nama,
                currentUserEmail: widget.email,
                onStatusChanged: () {
                  setState(() {});
                  unawaited(_simpanData());
                })));
  }

  void _bukaNotifikasi() {
    setState(() {
      for (final item in _notifikasi) {
        item.isRead = true;
      }
    });
    unawaited(_simpanData());
    showModalBottomSheet<void>(
        context: context,
        backgroundColor: UINColors.sand,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => SafeArea(
            child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .62,
                child: Column(children: [
                  const SizedBox(height: 12),
                  Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10))),
                  const Padding(
                      padding: EdgeInsets.fromLTRB(22, 20, 22, 12),
                      child: Row(children: [
                        Text('Pemberitahuan',
                            style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: UINColors.deep)),
                        Spacer(),
                        Icon(Icons.notifications_active_outlined,
                            color: UINColors.gold)
                      ])),
                  Expanded(
                      child: _notifikasi.isEmpty
                          ? const Center(
                              child: Text('Belum ada pemberitahuan.',
                                  style: TextStyle(color: UINColors.muted)))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: _notifikasi.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final item = _notifikasi[index];
                                return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: Row(children: [
                                      const CircleAvatar(
                                          backgroundColor: UINColors.mint,
                                          child: Icon(Icons.notifications_none,
                                              color: UINColors.primary,
                                              size: 19)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(item.title,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: UINColors.deep)),
                                            const SizedBox(height: 3),
                                            Text(item.message,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: UINColors.muted,
                                                    height: 1.3)),
                                            const SizedBox(height: 5),
                                            Text(_formatTanggal(item.waktu),
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: UINColors.muted))
                                          ]))
                                    ]));
                              }))
                ]))));
  }

  void _logout() async {
    await AppDataRepository()
        .updatePresence(email: widget.email, isOnline: false);
    await AuthService().clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  void _kembaliDashboard() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => DashboardScreen(
                nim: widget.nim, nama: widget.nama, email: widget.email)));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      JelajahScreen(
          daftarBarang: _daftarBarang,
          onKlaimTap: _bukaChatDariBarang,
          appStateStr: _appStateStr,
          detikSesi: _detikSesi,
          currentUserEmail: widget.email,
          onDelete: _hapusBarang,
          onRefresh: () => _sinkronkanDariServer(showPopup: false),
          unreadNotificationCount: _totalUnreadNotifikasi,
          onNotificationsTap: _bukaNotifikasi),
      LaporBarangScreen(
          onLaporanDibuat: _tambahBarang, defaultNama: widget.nama),
      DaftarChatScreen(daftarSesi: _daftarSesiChat, onSesiTap: _bukaChat),
      ProfilScreen(
          nama: widget.nama,
          nim: widget.nim,
          email: widget.email,
          detikSesi: _detikSesi,
          onLogout: _logout)
    ];
    return Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        floatingActionButton: FloatingActionButton.small(
            onPressed: _kembaliDashboard,
            tooltip: 'Kembali ke Dashboard',
            backgroundColor: UINColors.gold,
            foregroundColor: UINColors.deep,
            child: const Icon(Icons.home_rounded)),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: NavigationBar(
            height: 74,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            backgroundColor: Colors.white,
            indicatorColor: UINColors.gold.withValues(alpha: .22),
            destinations: [
              const NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore, color: UINColors.primary),
                  label: 'Jelajah'),
              const NavigationDestination(
                  icon: Icon(Icons.add_circle_outline),
                  selectedIcon:
                      Icon(Icons.add_circle, color: UINColors.primary),
                  label: 'Lapor'),
              NavigationDestination(
                  icon: _BadgeIcon(
                      icon: Icons.chat_bubble_outline, count: _totalUnreadChat),
                  selectedIcon: _BadgeIcon(
                      icon: Icons.chat_bubble,
                      count: _totalUnreadChat,
                      selected: true),
                  label: 'Chat'),
              const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: UINColors.primary),
                  label: 'Profil')
            ]));
  }
}
