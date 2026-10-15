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

  Future<void> _ubahPengguna(AdminUser user) async {
    final formKey = GlobalKey<FormState>();
    final nim = TextEditingController(text: user.nim);
    final email = TextEditingController(text: user.email);
    final nama = TextEditingController(text: user.nama);
    final simpan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah akun pengguna'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                  controller: nama,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama wajib diisi'
                      : null),
              TextFormField(
                  controller: nim,
                  decoration: const InputDecoration(labelText: 'NIM'),
                  validator: (v) =>
                      v == null || !RegExp(r'^\d+$').hasMatch(v.trim())
                          ? 'NIM harus berupa angka'
                          : null),
              TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email kampus'),
                  validator: (v) => v == null ||
                          !RegExp(r'^\d+@student\.uin-malang\.ac\.id$')
                              .hasMatch(v.trim())
                      ? 'Gunakan format NIM@student.uin-malang.ac.id'
                      : null),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Simpan')),
        ],
      ),
    );
    if (simpan == true && mounted) {
      try {
        await AppDataRepository().updateAdminUser(
            token: widget.adminToken,
            currentEmail: user.email,
            nim: nim.text.trim(),
            email: email.text.trim(),
            nama: nama.text.trim());
        _pesanAdmin('Data akun berhasil diperbarui.');
        await _muatData();
      } catch (error) {
        _pesanAdmin(error.toString().replaceFirst('Exception: ', ''));
      }
    }
    nim.dispose();
    email.dispose();
    nama.dispose();
  }

  Future<void> _hapusPengguna(AdminUser user) async {
    final hapus = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus akun?'),
        content: Text(
            'Akun ${user.nama} (${user.email}) akan dihapus. Laporan yang terkait tetap tersimpan tanpa identitas pemilik.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          FilledButton.tonal(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus akun')),
        ],
      ),
    );
    if (hapus != true || !mounted) return;
    try {
      await AppDataRepository()
          .deleteAdminUser(token: widget.adminToken, email: user.email);
      _pesanAdmin('Akun berhasil dihapus.');
      await _muatData();
    } catch (error) {
      _pesanAdmin(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _pesanAdmin(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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

  Widget _metric(String value, String label, IconData icon, double width) {
    return SizedBox(
      width: width,
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

  Widget _buildUsers(List<AdminUser> users) {
    if (users.isEmpty) {
      return const Center(child: Text('Belum ada akun pengguna.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final user = users[index];
        return Card(
            child: ListTile(
          leading: CircleAvatar(
              backgroundColor:
                  user.isOnline ? UINColors.mint : const Color(0xFFF0F1F3),
              child: Icon(user.isOnline ? Icons.circle : Icons.person_outline,
                  color: user.isOnline ? UINColors.primary : UINColors.muted,
                  size: 20)),
          title: Text(user.nama,
              style: const TextStyle(
                  color: UINColors.deep, fontWeight: FontWeight.w800)),
          subtitle:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.email),
            Text('NIM: ${user.nim}'),
            PresenceLabel(
                isOnline: user.isOnline, lastSeen: user.lastSeen, compact: true)
          ]),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            tooltip: 'Kelola akun',
            onSelected: (value) {
              if (value == 'edit') _ubahPengguna(user);
              if (value == 'delete') _hapusPengguna(user);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Ubah akun')),
              PopupMenuItem(value: 'delete', child: Text('Hapus akun'))
            ],
          ),
        ));
      },
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
      body: ResponsivePage(
        maxWidth: 1800,
        child: _isLoading
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
                        length: 4,
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
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      const spacing = 8.0;
                                      final columns =
                                          constraints.maxWidth >= 820 ? 4 : 2;
                                      final width = (constraints.maxWidth -
                                              spacing * (columns - 1)) /
                                          columns;
                                      return Wrap(
                                        spacing: spacing,
                                        runSpacing: spacing,
                                        children: [
                                          _metric(
                                              '${snapshot.reports.length}',
                                              'Semua laporan',
                                              Icons.inventory_2_outlined,
                                              width),
                                          _metric(
                                              '${snapshot.reports.where((r) => r.status == StatusBarang.selesai).length}',
                                              'Laporan selesai',
                                              Icons.task_alt,
                                              width),
                                          _metric(
                                              '${snapshot.users.length}',
                                              'Akun pengguna',
                                              Icons.people_outline,
                                              width),
                                          _metric(
                                              '${snapshot.chats.length}',
                                              'Percakapan',
                                              Icons.chat_bubble_outline,
                                              width),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const TabBar(
                              tabs: [
                                Tab(text: 'Laporan'),
                                Tab(text: 'Chat'),
                                Tab(text: 'Notifikasi'),
                                Tab(text: 'Pengguna'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildReports(snapshot.reports),
                                  _buildChats(snapshot.chats),
                                  _buildNotifications(snapshot.notifications),
                                  _buildUsers(snapshot.users),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
