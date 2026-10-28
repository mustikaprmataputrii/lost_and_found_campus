part of '../main.dart';

class DaftarChatScreen extends StatelessWidget {
  final List<SesiChat> daftarSesi;
  final void Function(SesiChat) onSesiTap;
  const DaftarChatScreen(
      {super.key, required this.daftarSesi, required this.onSesiTap});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Chat klaim')),
      body: ResponsivePage(
          maxWidth: 1600,
          child: daftarSesi.isEmpty
              ? const Center(
                  child: Text('Belum ada percakapan aktif.',
                      style: TextStyle(color: UINColors.muted)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                      const Text('Percakapanmu',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: UINColors.deep)),
                      const SizedBox(height: 5),
                      const Text(
                          'Komunikasikan proses pengembalian dengan aman.',
                          style: TextStyle(color: UINColors.muted)),
                      const SizedBox(height: 18),
                      ...daftarSesi.map((sesi) {
                        final last = sesi.pesanList.isEmpty
                            ? 'Belum ada pesan'
                            : sesi.pesanList.last.teks;
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                                child: ListTile(
                                    onTap: () => onSesiTap(sesi),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: Badge(
                                        isLabelVisible: sesi.unreadCount > 0,
                                        label: Text('${sesi.unreadCount}'),
                                        backgroundColor: UINColors.coral,
                                        child: const CircleAvatar(
                                            backgroundColor: UINColors.mint,
                                            child: Icon(
                                                Icons.chat_bubble_outline,
                                                color: UINColors.primary))),
                                    title: Text(
                                        sesi.peerName ?? sesi.barang.pelapor,
                                        style: TextStyle(
                                            fontWeight: sesi.unreadCount > 0
                                                ? FontWeight.w900
                                                : FontWeight.w700,
                                            color: UINColors.deep)),
                                    subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(sesi.barang.nama,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: UINColors.muted)),
                                              const SizedBox(height: 3),
                                              Text(last,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color:
                                                          sesi.unreadCount > 0
                                                              ? UINColors.ink
                                                              : UINColors.muted,
                                                      fontWeight:
                                                          sesi.unreadCount > 0
                                                              ? FontWeight.w700
                                                              : FontWeight
                                                                  .normal)),
                                              const SizedBox(height: 5),
                                              PresenceLabel(
                                                  isOnline: sesi.isOnline,
                                                  lastSeen: sesi.lastSeen,
                                                  compact: true)
                                            ])),
                                    trailing: const Icon(Icons.chevron_right,
                                        color: UINColors.muted))));
                      })
                    ])));
}

class RoomChatScreen extends StatefulWidget {
  final SesiChat sesi;
  final String currentUserName;
  final String currentUserEmail;
  final VoidCallback onStatusChanged;
  final Future<SesiChat?> Function(String text)? onSendMessage;
  final Future<SesiChat?> Function()? onRefresh;
  final Future<SesiChat?> Function(String messageId)? onDeleteMessage;
  final Future<SesiChat?> Function()? onRequestClaim;
  final Future<SesiChat?> Function({required bool approve})? onRespondToClaim;
  const RoomChatScreen(
      {super.key,
      required this.sesi,
      required this.currentUserName,
      required this.currentUserEmail,
      required this.onStatusChanged,
      this.onSendMessage,
      this.onRefresh,
      this.onDeleteMessage,
      this.onRequestClaim,
      this.onRespondToClaim});
  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  late SesiChat _sesi = widget.sesi;
  Timer? _refreshTimer;
  bool _sending = false;
  bool _claimBusy = false;

  @override
  void initState() {
    super.initState();
    if (widget.onRefresh != null) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        unawaited(_refreshFromServer());
      });
    }
  }

  Future<void> _refreshFromServer() async {
    try {
      final refreshed = await widget.onRefresh?.call();
      if (refreshed != null && mounted) setState(() => _sesi = refreshed);
    } catch (_) {
      // Room tetap menampilkan pesan terakhir yang berhasil dimuat.
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _kirimPesan() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    if (widget.onSendMessage != null) {
      setState(() => _sending = true);
      try {
        final refreshed = await widget.onSendMessage!(text);
        if (!mounted) return;
        setState(() {
          if (refreshed != null) {
            _sesi = refreshed;
          } else {
            // Pesan sudah tersimpan di server tetapi sinkronisasi ulang gagal;
            // tetap tampilkan bubble supaya pengirim mendapat umpan balik.
            _sesi.pesanList.add(PesanChat(
                pengirim: widget.currentUserName,
                pengirimEmail: widget.currentUserEmail,
                teks: text,
                waktu: DateTime.now(),
                isMe: true));
          }
        });
        _inputController.clear();
        _scrollToLatest();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', ''))));
        }
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }
    setState(() => _sesi.pesanList.add(PesanChat(
        pengirim: widget.currentUserName,
        pengirimEmail: widget.currentUserEmail,
        teks: text,
        waktu: DateTime.now(),
        isMe: true)));
    widget.onStatusChanged();
    _inputController.clear();
    _scrollToLatest();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<bool> _konfirmasi({
    required String title,
    required String message,
    required String confirmLabel,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel)),
          ],
        ),
      ) ??
      false;

  Future<void> _batalkanPesan(PesanChat message) async {
    final id = message.id;
    final callback = widget.onDeleteMessage;
    if (id == null || callback == null) return;
    final confirmed = await _konfirmasi(
      title: 'Batalkan pengiriman pesan?',
      message: 'Pesan ini akan dihapus dari percakapan untuk kedua pihak.',
      confirmLabel: 'Batalkan pesan',
    );
    if (!confirmed || !mounted) return;
    try {
      final refreshed = await callback(id);
      if (!mounted) return;
      setState(() {
        if (refreshed != null) {
          _sesi = refreshed;
        } else {
          _sesi.pesanList.removeWhere((item) => item.id == id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pesan berhasil dibatalkan untuk kedua pihak.'),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
      ));
    }
  }

  Future<void> _ajukanKlaim() async {
    final callback = widget.onRequestClaim;
    if (callback == null || _claimBusy) return;
    final confirmed = await _konfirmasi(
      title: 'Ajukan klaim barang?',
      message:
          'Pemilik laporan akan diminta menyetujui klaim ini. Status selesai hanya berubah setelah pemilik menyetujuinya.',
      confirmLabel: 'Ajukan klaim',
    );
    if (!confirmed || !mounted) return;
    setState(() => _claimBusy = true);
    try {
      final refreshed = await callback();
      if (!mounted) return;
      setState(() {
        if (refreshed != null) _sesi = refreshed;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ));
      }
    } finally {
      if (mounted) setState(() => _claimBusy = false);
    }
  }

  Future<void> _tanggapiKlaim(bool approve) async {
    final callback = widget.onRespondToClaim;
    if (callback == null || _claimBusy) return;
    final confirmed = await _konfirmasi(
      title: approve ? 'Setujui klaim?' : 'Tolak klaim?',
      message: approve
          ? 'Klaim akan disepakati oleh pemilik dan pengaju, lalu laporan ditandai selesai.'
          : 'Klaim ini ditolak dan laporan akan kembali tersedia.',
      confirmLabel: approve ? 'Setujui' : 'Tolak',
    );
    if (!confirmed || !mounted) return;
    setState(() => _claimBusy = true);
    try {
      final refreshed = await callback(approve: approve);
      if (!mounted) return;
      setState(() {
        if (refreshed != null) _sesi = refreshed;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ));
      }
    } finally {
      if (mounted) setState(() => _claimBusy = false);
    }
  }

  Widget? _buildClaimPanel() {
    final report = _sesi.barang;
    final isOwner = report.pemilikEmail == widget.currentUserEmail;
    final isClaimant = report.claimantEmail == widget.currentUserEmail;
    if (report.status == StatusBarang.selesai) {
      return _claimNotice(
          Icons.verified_outlined, 'Klaim disetujui kedua pihak.');
    }
    if (report.status == StatusBarang.prosesKlaim) {
      if (isOwner && widget.onRespondToClaim != null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          color: UINColors.mint,
          child: Column(children: [
            Text('Permintaan klaim dari ${report.claimantEmail ?? 'pengguna'}'),
            const SizedBox(height: 7),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _claimBusy ? null : () => _tanggapiKlaim(false),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _claimBusy ? null : () => _tanggapiKlaim(true),
                  child: const Text('Setujui klaim'),
                ),
              ),
            ]),
          ]),
        );
      }
      return _claimNotice(
        Icons.hourglass_top_rounded,
        isClaimant
            ? 'Menunggu persetujuan pemilik laporan.'
            : 'Klaim sedang menunggu persetujuan pemilik.',
      );
    }
    if (!isOwner && widget.onRequestClaim != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: UINColors.mint,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _claimBusy ? null : _ajukanKlaim,
            icon: const Icon(Icons.handshake_outlined),
            label: Text(_claimBusy ? 'Mengirim permintaan...' : 'Ajukan klaim'),
          ),
        ),
      );
    }
    return null;
  }

  Widget _claimNotice(IconData icon, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: UINColors.mint,
        child: Row(children: [
          Icon(icon, color: UINColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );

  Widget _buildMessage(PesanChat message) {
    final canUnsend =
        message.isMe && message.id != null && widget.onDeleteMessage != null;
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Tooltip(
        message: canUnsend ? 'Tekan lama untuk membatalkan pesan' : '',
        child: GestureDetector(
          onLongPress: canUnsend ? () => _batalkanPesan(message) : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
            constraints: const BoxConstraints(maxWidth: 310),
            decoration: BoxDecoration(
              color: message.isMe ? UINColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.isMe ? 18 : 4),
                bottomRight: Radius.circular(message.isMe ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!message.isMe)
                  Text(message.pengirim,
                      style: const TextStyle(
                          fontSize: 10,
                          color: UINColors.primary,
                          fontWeight: FontWeight.w800)),
                Text(message.teks,
                    style: TextStyle(
                        color: message.isMe ? Colors.white : UINColors.ink,
                        height: 1.35)),
                const SizedBox(height: 4),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_formatJam(message.waktu),
                      style: TextStyle(
                          color:
                              message.isMe ? Colors.white70 : UINColors.muted,
                          fontSize: 9)),
                  if (canUnsend)
                    PopupMenuButton<String>(
                      tooltip: 'Opsi pesan',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      iconSize: 17,
                      icon: const Icon(Icons.more_horiz, color: Colors.white70),
                      onSelected: (_) => _batalkanPesan(message),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'unsend',
                          child: Text('Batalkan pengiriman'),
                        ),
                      ],
                    ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_sesi.peerName ?? _sesi.barang.pelapor,
                style: const TextStyle(fontSize: 16)),
            Row(children: [
              Text('${_sesi.barang.nama} • ',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                      color: UINColors.muted)),
              PresenceLabel(
                  isOnline: _sesi.isOnline,
                  lastSeen: _sesi.lastSeen,
                  compact: true)
            ])
          ]),
          actions: const [SizedBox(width: 6)]),
      body: ResponsivePage(
          maxWidth: 1600,
          child: Column(children: [
            if (_buildClaimPanel() case final panel?) panel,
            Expanded(
                child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                    itemCount: _sesi.pesanList.length,
                    itemBuilder: (_, index) =>
                        _buildMessage(_sesi.pesanList[index]))),
            Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                color: Colors.white,
                child: Row(children: [
                  Expanded(
                      child: TextField(
                          controller: _inputController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _kirimPesan(),
                          decoration: const InputDecoration(
                              hintText: 'Tulis pesan...',
                              filled: true,
                              fillColor: UINColors.sand,
                              border: InputBorder.none))),
                  const SizedBox(width: 8),
                  IconButton.filled(
                      onPressed: _sending ? null : _kirimPesan,
                      style: IconButton.styleFrom(
                          backgroundColor: UINColors.primary,
                          foregroundColor: Colors.white),
                      icon: const Icon(Icons.send_rounded))
                ]))
          ])));
}
