part of '../main.dart';

class DetailBarangScreen extends StatelessWidget {
  final BarangItem item;
  final VoidCallback onKlaim;
  final String? currentUserEmail;
  final Future<void> Function()? onDelete;
  final List<ReportMatch> kandidat;
  final ValueChanged<BarangItem>? onKandidatTap;
  const DetailBarangScreen(
      {super.key,
      required this.item,
      required this.onKlaim,
      this.currentUserEmail,
      this.onDelete,
      this.kandidat = const [],
      this.onKandidatTap});

  Future<void> _konfirmasiHapus(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus laporan?'),
        content: const Text(
            'Laporan ini akan dihapus dari database dan tidak terlihat oleh akun lain.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: UINColors.coral),
              child: const Text('Hapus'))
        ],
      ),
    );
    if (confirmed != true || onDelete == null) return;
    try {
      await onDelete!();
    } catch (error) {
      if (context.mounted) {
        final message = error.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Laporan gagal dihapus. $message'),
            behavior: SnackBarBehavior.floating));
      }
      return;
    }
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final found = item.jenis == JenisLaporan.ditemukan;
    return Scaffold(
        appBar: AppBar(title: const Text('Detail laporan'), actions: [
          if (onDelete != null && item.pemilikEmail == currentUserEmail)
            IconButton(
                onPressed: () => _konfirmasiHapus(context),
                tooltip: 'Hapus laporan',
                icon: const Icon(Icons.delete_outline, color: UINColors.coral)),
          const SizedBox(width: 8)
        ]),
        body: ResponsivePage(
            maxWidth: 1300,
            child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  Container(
                      height: 230,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          color:
                              found ? UINColors.mint : const Color(0xFFFFEEE9),
                          borderRadius: BorderRadius.circular(26)),
                      child: item.fotoBytes != null
                          ? Image.memory(item.fotoBytes!, fit: BoxFit.cover)
                          : Center(
                              child: Icon(
                                  found
                                      ? Icons.inventory_2_outlined
                                      : Icons.search_rounded,
                                  size: 88,
                                  color: found
                                      ? UINColors.primary
                                      : UINColors.coral))),
                  const SizedBox(height: 20),
                  Row(children: [
                    StatusPill(
                        label: found ? 'BARANG DITEMUKAN' : 'BARANG HILANG',
                        color: found ? UINColors.primary : UINColors.coral),
                    const Spacer(),
                    _StatusBadge(status: item.status)
                  ]),
                  const SizedBox(height: 10),
                  Text(item.nama,
                      style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          color: UINColors.deep)),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    InfoChip(
                        icon: Icons.location_on_outlined, label: item.lokasi),
                    InfoChip(icon: Icons.person_outline, label: item.pelapor)
                  ]),
                  const SizedBox(height: 26),
                  const Text('Deskripsi',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: UINColors.deep,
                          fontSize: 16)),
                  const SizedBox(height: 7),
                  Text(item.deskripsi,
                      style: const TextStyle(
                          color: UINColors.muted, height: 1.55)),
                  if (kandidat.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    Row(children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: UINColors.primary, size: 21),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: Text('Kandidat cocok',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: UINColors.deep))),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                              color: UINColors.gold.withValues(alpha: .22),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('${kandidat.length}',
                              style: const TextStyle(
                                  color: UINColors.deep,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900)))
                    ]),
                    const SizedBox(height: 6),
                    const Text(
                        'Laporan dengan jenis sebaliknya yang paling mirip. Ketuk untuk melihat detail.',
                        style: TextStyle(color: UINColors.muted, fontSize: 12)),
                    const SizedBox(height: 12),
                    ...kandidat.map((match) => _CandidateMatchCard(
                        match: match,
                        onTap: onKandidatTap == null
                            ? null
                            : () => onKandidatTap!(match.report)))
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onKlaim();
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: Text(found
                              ? 'Hubungi penemu'
                              : 'Beri informasi ke pemilik'),
                          style: FilledButton.styleFrom(
                              backgroundColor: UINColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)))))
                ])));
  }
}

class _CandidateMatchCard extends StatelessWidget {
  final ReportMatch match;
  final VoidCallback? onTap;

  const _CandidateMatchCard({required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    final item = match.report;
    final found = item.jenis == JenisLaporan.ditemukan;
    return Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ItemImage(
                                bytes: item.fotoBytes, found: found, size: 68),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    StatusPill(
                                        label: found ? 'DITEMUKAN' : 'HILANG',
                                        color: found
                                            ? UINColors.primary
                                            : UINColors.coral),
                                    const Spacer(),
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: UINColors.gold
                                                .withValues(alpha: .22),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Text('${match.percent}% cocok',
                                            style: const TextStyle(
                                                color: UINColors.deep,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900)))
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(item.nama,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: UINColors.ink)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 14, color: UINColors.muted),
                                    const SizedBox(width: 3),
                                    Expanded(
                                        child: Text(item.lokasi,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: UINColors.muted,
                                                fontSize: 11))),
                                    const SizedBox(width: 8),
                                    Text(_formatTanggal(item.tanggal),
                                        style: const TextStyle(
                                            color: UINColors.muted,
                                            fontSize: 9))
                                  ])
                                ])),
                            if (onTap != null) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded,
                                  color: UINColors.muted)
                            ]
                          ]),
                      if (match.reasons.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: match.reasons
                                .map((reason) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: UINColors.mint,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(reason,
                                        style: const TextStyle(
                                            color: UINColors.deep,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700))))
                                .toList())
                      ],
                      if (item.deskripsi.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(item.deskripsi,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: UINColors.muted,
                                fontSize: 11,
                                height: 1.4))
                      ]
                    ]))));
  }
}
