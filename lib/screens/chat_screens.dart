part of '../main.dart';

class DaftarChatScreen extends StatelessWidget {
  final List<SesiChat> daftarSesi;
  final void Function(SesiChat) onSesiTap;
  const DaftarChatScreen(
      {super.key, required this.daftarSesi, required this.onSesiTap});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Chat klaim')),
      body: daftarSesi.isEmpty
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
                  const Text('Komunikasikan proses pengembalian dengan aman.',
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
                                        child: Icon(Icons.chat_bubble_outline,
                                            color: UINColors.primary))),
                                title: Text(sesi.barang.nama,
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
                                          Text(last,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: sesi.unreadCount > 0
                                                      ? UINColors.ink
                                                      : UINColors.muted,
                                                  fontWeight:
                                                      sesi.unreadCount > 0
                                                          ? FontWeight.w700
                                                          : FontWeight.normal)),
                                          const SizedBox(height: 5),
                                          PresenceLabel(
                                              isOnline: sesi.isOnline,
                                              lastSeen: sesi.lastSeen,
                                              compact: true)
                                        ])),
                                trailing: const Icon(Icons.chevron_right,
                                    color: UINColors.muted))));
                  })
                ]));
}

class RoomChatScreen extends StatefulWidget {
  final SesiChat sesi;
  final String currentUserName;
  final VoidCallback onStatusChanged;
  const RoomChatScreen(
      {super.key,
      required this.sesi,
      required this.currentUserName,
      required this.onStatusChanged});
  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _kirimPesan() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() => widget.sesi.pesanList.add(PesanChat(
        pengirim: widget.currentUserName,
        teks: text,
        waktu: DateTime.now(),
        isMe: true)));
    widget.onStatusChanged();
    _inputController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _selesaikanKlaim() {
    showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Selesaikan klaim?'),
                content: const Text(
                    'Tandai barang ini sudah diserahkan kepada pemiliknya?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () {
                        setState(() =>
                            widget.sesi.barang.status = StatusBarang.selesai);
                        widget.onStatusChanged();
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Ya, selesai'))
                ]));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.sesi.barang.nama, style: const TextStyle(fontSize: 16)),
            Row(children: [
              Text('${widget.sesi.barang.pelapor} • ',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                      color: UINColors.muted)),
              PresenceLabel(
                  isOnline: widget.sesi.isOnline,
                  lastSeen: widget.sesi.lastSeen,
                  compact: true)
            ])
          ]),
          actions: [
            if (widget.sesi.barang.status != StatusBarang.selesai)
              IconButton(
                  onPressed: _selesaikanKlaim,
                  tooltip: 'Tandai selesai',
                  icon: const Icon(Icons.check_circle_outline)),
            const SizedBox(width: 6)
          ]),
      body: Column(children: [
        Expanded(
            child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                itemCount: widget.sesi.pesanList.length,
                itemBuilder: (_, index) {
                  final message = widget.sesi.pesanList[index];
                  return Align(
                      alignment: message.isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
                          constraints: const BoxConstraints(maxWidth: 310),
                          decoration: BoxDecoration(
                              color: message.isMe
                                  ? UINColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft:
                                      Radius.circular(message.isMe ? 18 : 4),
                                  bottomRight:
                                      Radius.circular(message.isMe ? 4 : 18))),
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
                                        color: message.isMe
                                            ? Colors.white
                                            : UINColors.ink,
                                        height: 1.35)),
                                const SizedBox(height: 4),
                                Text(_formatJam(message.waktu),
                                    style: TextStyle(
                                        color: message.isMe
                                            ? Colors.white70
                                            : UINColors.muted,
                                        fontSize: 9))
                              ])));
                })),
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
                  onPressed: _kirimPesan,
                  style: IconButton.styleFrom(
                      backgroundColor: UINColors.primary,
                      foregroundColor: Colors.white),
                  icon: const Icon(Icons.send_rounded))
            ]))
      ]));
}
