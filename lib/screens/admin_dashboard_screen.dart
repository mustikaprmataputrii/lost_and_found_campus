part of '../main.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminEmail;
  final String adminName;
  final String adminToken;

  const AdminDashboardScreen({
    super.key,
    required this.adminEmail,
    required this.adminName,
    required this.adminToken,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  LocalDataSnapshot? _snapshot;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshot =
          await AppDataRepository().loadAdmin(token: widget.adminToken);
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService().clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _bukaChat(SesiChat sesi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomChatScreen(
          sesi: sesi,
          currentUserName: widget.adminName,
          currentUserEmail: widget.adminEmail,
          onStatusChanged: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  void _bukaLaporan(BarangItem item) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.nama),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(item.jenis == JenisLaporan.ditemukan
                  ? 'Jenis: Barang ditemukan'
                  : 'Jenis: Barang hilang'),
              const SizedBox(height: 8),
              Text('Lokasi: ${item.lokasi}'),
              Text('Pelapor: ${item.pelapor}'),
              Text('Kontak: ${item.kontak}'),
              Text('Status: ${item.status.name}'),
              const SizedBox(height: 12),
              Text(item.deskripsi),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: UINColors.gold, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .72),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReports(List<BarangItem> reports) {
    if (reports.isEmpty) {
      return const Center(child: Text('Belum ada laporan.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final item = reports[index];
        final found = item.jenis == JenisLaporan.ditemukan;
        return Card(
          child: ListTile(
            onTap: () => _bukaLaporan(item),
            leading: CircleAvatar(
              backgroundColor: found ? UINColors.mint : const Color(0xFFFFEEE9),
              child: Icon(
                found ? Icons.inventory_2_outlined : Icons.search_rounded,
                color: found ? UINColors.primary : UINColors.coral,
              ),
            ),
            title: Text(
              item.nama,
              style: const TextStyle(
                color: UINColors.deep,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '${item.lokasi} - ${item.pelapor} - ${_formatTanggal(item.tanggal)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _buildChats(List<SesiChat> chats) {
    if (chats.isEmpty) {
      return const Center(child: Text('Belum ada percakapan.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final chat = chats[index];
        final preview = chat.pesanList.isEmpty
            ? 'Belum ada pesan'
            : chat.pesanList.last.teks;
        return Card(
          child: ListTile(
            onTap: () => _bukaChat(chat),
            leading: Badge(
              isLabelVisible: chat.unreadCount > 0,
              label: Text('${chat.unreadCount}'),
              backgroundColor: UINColors.coral,
              child: const CircleAvatar(
                backgroundColor: UINColors.mint,
                child:
                    Icon(Icons.chat_bubble_outline, color: UINColors.primary),
              ),
            ),
            title: Text(
              chat.barang.nama,
              style: const TextStyle(
                color: UINColors.deep,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                PresenceLabel(
                  isOnline: chat.isOnline,
                  lastSeen: chat.lastSeen,
                  compact: true,
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _buildNotifications(List<NotifikasiItem> notifications) {
    if (notifications.isEmpty) {
      return const Center(child: Text('Belum ada notifikasi.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final notification = notifications[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: UINColors.mint,
              child: Icon(Icons.notifications_none, color: UINColors.primary),
            ),
            title: Text(
              notification.title,
              style: const TextStyle(
                color: UINColors.deep,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '${notification.message}\n${_formatTanggal(notification.waktu)}',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(12),
          child: UinLogo(size: 28),
        ),
        title: const Text('Admin TEMU'),
        actions: [
          IconButton(
            onPressed: _muatData,
            tooltip: 'Muat ulang data',
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            color: UINColors.coral, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: UINColors.muted),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _muatData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : snapshot == null
                  ? const Center(child: Text('Data admin belum tersedia.'))
                  : DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [UINColors.deep, UINColors.primary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: UINColors.gold,
                                      child: Icon(Icons.admin_panel_settings,
                                          color: UINColors.deep),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Halo, ${widget.adminName}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 19,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          Text(
                                            widget.adminEmail,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: .72),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    _metric('${snapshot.reports.length}',
                                        'Laporan', Icons.inventory_2_outlined),
                                    const SizedBox(width: 8),
                                    _metric('${snapshot.chats.length}', 'Chat',
                                        Icons.chat_bubble_outline),
                                    const SizedBox(width: 8),
                                    _metric('${snapshot.notifications.length}',
                                        'Notifikasi', Icons.notifications_none),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const TabBar(
                            tabs: [
                              Tab(text: 'Laporan'),
                              Tab(text: 'Chat'),
                              Tab(text: 'Notifikasi'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildReports(snapshot.reports),
                                _buildChats(snapshot.chats),
                                _buildNotifications(snapshot.notifications),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
