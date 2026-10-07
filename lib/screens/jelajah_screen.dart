part of '../main.dart';

class JelajahScreen extends StatefulWidget {
  final List<BarangItem> daftarBarang;
  final void Function(BarangItem) onKlaimTap;
  final String appStateStr;
  final int detikSesi;
  final int unreadNotificationCount;
  final VoidCallback onNotificationsTap;
  const JelajahScreen(
      {super.key,
      required this.daftarBarang,
      required this.onKlaimTap,
      required this.appStateStr,
      required this.detikSesi,
      required this.unreadNotificationCount,
      required this.onNotificationsTap});
  @override
  State<JelajahScreen> createState() => _JelajahScreenState();
}

class _JelajahScreenState extends State<JelajahScreen> {
  String _query = '';
  JenisLaporan? _filter;
  String _lokasi = 'Semua lokasi';
  final _lokasiList = const [
    'Semua lokasi',
    'Saintek Lt. 3',
    'Perpustakaan Pusat',
    'Masjid Ulul Albab',
    'Gedung Rektorat',
    'Fakultas Tarbiyah',
    'Fakultas Ekonomi',
    'Kantin Kampus 1'
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = widget.daftarBarang.where((item) {
      final q = _query.toLowerCase();
      return (item.nama.toLowerCase().contains(q) ||
              item.deskripsi.toLowerCase().contains(q)) &&
          (_lokasi == 'Semua lokasi' || item.lokasi == _lokasi) &&
          (_filter == null || item.jenis == _filter);
    }).toList();
    return Scaffold(
      appBar: AppBar(
          leading: const Padding(
              padding: EdgeInsets.all(10),
              child: UinLogo(size: 25, withBackground: false)),
          title: const Text('TEMU UIN'),
          actions: [
            Badge(
                isLabelVisible: widget.unreadNotificationCount > 0,
                label: Text('${widget.unreadNotificationCount}'),
                backgroundColor: UINColors.coral,
                child: IconButton(
                    onPressed: widget.onNotificationsTap,
                    icon: const Icon(Icons.notifications_none_rounded))),
            const SizedBox(width: 8)
          ]),
      body: RefreshIndicator(
        color: UINColors.primary,
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            _buildHero(),
            const SizedBox(height: 20),
            Row(children: [
              const Text('Temuan terbaru',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: UINColors.deep)),
              const Spacer(),
              Text('${filtered.length} laporan',
                  style: const TextStyle(color: UINColors.muted, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                    hintText: 'Cari barang atau lokasi...',
                    prefixIcon:
                        Icon(Icons.search_rounded, color: UINColors.primary))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _lokasi,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: UINColors.primary),
                      items: _lokasiList
                          .map((lokasi) => DropdownMenuItem(
                              value: lokasi,
                              child: Text(lokasi,
                                  style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _lokasi = value ?? _lokasi),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                  selected: _filter == null,
                  label: const Text('Semua'),
                  onSelected: (_) => setState(() => _filter = null),
                  selectedColor: UINColors.gold.withValues(alpha: .35)),
              const SizedBox(width: 4),
              FilterChip(
                  selected: _filter == JenisLaporan.ditemukan,
                  label: const Text('Temuan'),
                  onSelected: (_) =>
                      setState(() => _filter = JenisLaporan.ditemukan),
                  selectedColor: UINColors.mint),
            ]),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Center(
                      child: Text('Belum ada barang yang cocok.',
                          style: TextStyle(color: UINColors.muted))))
            else
              ...filtered.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ItemBarangCard(
                      item: item,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DetailBarangScreen(
                                  item: item,
                                  onKlaim: () => widget.onKlaimTap(item))))))),
            const SizedBox(height: 8),
            Text('Sesi ${widget.appStateStr} • ${widget.detikSesi} detik',
                textAlign: TextAlign.center,
                style: const TextStyle(color: UINColors.muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() => Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [UINColors.deep, UINColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(26)),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Assalamu'alaikum,",
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .72), fontSize: 13)),
          const SizedBox(height: 4),
          const Text('Temukan kembali\nyang berarti.',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  height: 1.05)),
          const SizedBox(height: 12),
          Text('Laporkan, temukan, dan bantu sesama warga kampus.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 12,
                  height: 1.35))
        ])),
        Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: UINColors.gold.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(22)),
            child: const UinLogo(size: 64))
      ]));
}
