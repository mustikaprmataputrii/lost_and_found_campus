part of '../main.dart';

class DetailBarangScreen extends StatelessWidget {
  final BarangItem item;
  final VoidCallback onKlaim;
  final String? currentUserEmail;
  final Future<void> Function()? onDelete;
  const DetailBarangScreen(
      {super.key,
      required this.item,
      required this.onKlaim,
      this.currentUserEmail,
      this.onDelete});

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
    await onDelete!();
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
        body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Container(
                  height: 230,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                      color: found ? UINColors.mint : const Color(0xFFFFEEE9),
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
                InfoChip(icon: Icons.location_on_outlined, label: item.lokasi),
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
                  style: const TextStyle(color: UINColors.muted, height: 1.55)),
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
            ]));
  }
}
