part of '../main.dart';

class DashboardScreen extends StatelessWidget {
  final String nim;
  final String nama;
  final String email;

  const DashboardScreen(
      {super.key, required this.nim, required this.nama, required this.email});

  void _masukAplikasi(BuildContext context, {int initialIndex = 0}) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => MainNavigationScreen(
                nim: nim,
                nama: nama,
                email: email,
                initialIndex: initialIndex)));
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          const Text('Assalamuâ€™alaikum,',
              style: TextStyle(
                  color: UINColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(nama,
              style: const TextStyle(
                  color: UINColors.deep,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(email,
              style: const TextStyle(color: UINColors.muted, fontSize: 12)),
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                const _DashboardMetric(value: '03', label: 'Temuan aktif'),
                const SizedBox(width: 10),
                const _DashboardMetric(value: '02', label: 'Pesan baru'),
                const SizedBox(width: 10),
                _DashboardMetric(value: nim, label: 'NIM terdaftar')
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
                    onTap: () => _masukAplikasi(context))),
            const SizedBox(width: 12),
            Expanded(
                child: _DashboardAction(
                    icon: Icons.add_a_photo_outlined,
                    title: 'Buat laporan',
                    subtitle: 'Bantu warga kampus',
                    color: const Color(0xFFFFEEE9),
                    onTap: () => _masukAplikasi(context, initialIndex: 1)))
          ]),
          const SizedBox(height: 24),
          const Text('Ringkasan hari ini',
              style: TextStyle(
                  color: UINColors.deep,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Card(
              child: Column(children: [
            ListTile(
                leading: CircleAvatar(
                    backgroundColor: UINColors.mint,
                    child: Icon(Icons.chat_bubble_outline,
                        color: UINColors.primary)),
                title: Text('Ada 2 pesan yang menunggu',
                    style: TextStyle(
                        color: UINColors.deep, fontWeight: FontWeight.w800)),
                subtitle: Text('Tinjau percakapan klaim Kunci Motor Vario.')),
            Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
                leading: CircleAvatar(
                    backgroundColor: Color(0xFFFFF3D4),
                    child: Icon(Icons.shield_outlined, color: UINColors.gold)),
                title: Text('Akun terlindungi',
                    style: TextStyle(
                        color: UINColors.deep, fontWeight: FontWeight.w800)),
                subtitle: Text('Email resmi UIN Malang berhasil diverifikasi.'))
          ])),
          const SizedBox(height: 22),
          SizedBox(
              height: 54,
              child: FilledButton.icon(
                  onPressed: () => _masukAplikasi(context),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('MASUK KE RUANG TEMU',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  style: FilledButton.styleFrom(
                      backgroundColor: UINColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)))))
        ],
      ),
    );
  }
}
