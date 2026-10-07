part of '../main.dart';

class UinLogo extends StatelessWidget {
  final double size;
  final bool withBackground;
  const UinLogo({super.key, this.size = 56, this.withBackground = false});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset('assets/images/logo_uin_transparent.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.account_balance,
            size: size * .62, color: UINColors.primary));
    if (!withBackground) return image;
    return Container(
        width: size + 18,
        height: size + 18,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: UINColors.deep.withValues(alpha: .12),
                  blurRadius: 18,
                  offset: const Offset(0, 8))
            ]),
        child: image);
  }
}

class _DashboardMetric extends StatelessWidget {
  final String value;
  final String label;

  const _DashboardMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .7), fontSize: 9))
            ])));
  }
}

class _DashboardAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardAction(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(20)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: UINColors.primary, size: 28),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      color: UINColors.deep, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: UINColors.muted, fontSize: 11))
            ])));
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool selected;
  const _BadgeIcon(
      {required this.icon, required this.count, this.selected = false});
  @override
  Widget build(BuildContext context) => Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: UINColors.coral,
      child: Icon(icon, color: selected ? UINColors.primary : null));
}

class ItemBarangCard extends StatelessWidget {
  final BarangItem item;
  final VoidCallback onTap;
  const ItemBarangCard({super.key, required this.item, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final found = item.jenis == JenisLaporan.ditemukan;
    return Card(
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  _ItemImage(bytes: item.fotoBytes, found: found, size: 82),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          StatusPill(
                              label: found ? 'DITEMUKAN' : 'HILANG',
                              color:
                                  found ? UINColors.primary : UINColors.coral),
                          const Spacer(),
                          _StatusBadge(status: item.status)
                        ]),
                        const SizedBox(height: 8),
                        Text(item.nama,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: UINColors.ink)),
                        const SizedBox(height: 5),
                        Row(children: [
                          const Icon(Icons.location_on_outlined,
                              size: 15, color: UINColors.muted),
                          const SizedBox(width: 3),
                          Expanded(
                              child: Text(item.lokasi,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: UINColors.muted, fontSize: 12)))
                        ])
                      ]))
                ]))));
  }
}

class _ItemImage extends StatelessWidget {
  final Uint8List? bytes;
  final bool found;
  final double size;
  const _ItemImage(
      {required this.bytes, required this.found, required this.size});
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: found ? UINColors.mint : const Color(0xFFFFEEE9),
          borderRadius: BorderRadius.circular(18)),
      child: bytes != null
          ? Image.memory(bytes!, fit: BoxFit.cover)
          : Icon(found ? Icons.inventory_2_outlined : Icons.search_rounded,
              color: found ? UINColors.primary : UINColors.coral, size: 32));
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const StatusPill({super.key, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(7)),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .35)));
}

class _StatusBadge extends StatelessWidget {
  final StatusBarang status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final data = switch (status) {
      StatusBarang.belumDiklaim => ('Tersedia', UINColors.primary),
      StatusBarang.prosesKlaim => ('Proses', UINColors.gold),
      StatusBarang.selesai => ('Selesai', UINColors.muted)
    };
    return Text(data.$1,
        style: TextStyle(
            color: data.$2, fontSize: 10, fontWeight: FontWeight.w800));
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const InfoChip({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Chip(
      avatar: Icon(icon, color: UINColors.primary, size: 17),
      label: Text(label),
      backgroundColor: Colors.white,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            Icon(icon, color: UINColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: UINColors.deep))
          ])));
}

class PresenceLabel extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeen;
  final bool compact;

  const PresenceLabel(
      {super.key,
      required this.isOnline,
      required this.lastSeen,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: compact ? 7 : 8,
          height: compact ? 7 : 8,
          decoration: BoxDecoration(
              color: isOnline ? UINColors.primary : UINColors.muted,
              shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(
          isOnline
              ? 'Online'
              : 'Terakhir dilihat ${_formatRelativeTime(lastSeen)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: isOnline ? UINColors.primary : UINColors.muted,
              fontSize: compact ? 10 : 11,
              fontWeight: isOnline ? FontWeight.w800 : FontWeight.w500))
    ]);
  }
}
