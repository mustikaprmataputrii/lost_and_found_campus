part of '../main.dart';

class ProfilScreen extends StatelessWidget {
  final String nama;
  final String nim;
  final String email;
  final int detikSesi;
  final VoidCallback onLogout;
  const ProfilScreen(
      {super.key,
      required this.nama,
      required this.nim,
      required this.email,
      required this.detikSesi,
      required this.onLogout});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Profil saya')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [UINColors.deep, UINColors.primary]),
                    borderRadius: BorderRadius.circular(26)),
                child: Column(children: [
                  const CircleAvatar(
                      radius: 39,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          color: UINColors.primary, size: 45)),
                  const SizedBox(height: 12),
                  Text(nama,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(email,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 13),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: UINColors.gold.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(30)),
                      child: Text('NIM $nim â€¢ Terverifikasi UIN',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)))
                ])),
            const SizedBox(height: 16),
            Card(
                child: Column(children: [
              ListTile(
                  leading: const Icon(Icons.timer_outlined,
                      color: UINColors.primary),
                  title: const Text('Durasi sesi aktif'),
                  trailing: Text('$detikSesi detik',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: UINColors.deep))),
              const Divider(height: 1, indent: 16, endIndent: 16),
              const ListTile(
                  leading: Icon(Icons.verified_user_outlined,
                      color: UINColors.primary),
                  title: Text('Status akun'),
                  trailing: Text('Aktif',
                      style: TextStyle(
                          color: UINColors.primary,
                          fontWeight: FontWeight.w800)))
            ])),
            const SizedBox(height: 18),
            OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, color: UINColors.coral),
                label: const Text('Keluar akun',
                    style: TextStyle(color: UINColors.coral)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: UINColors.coral),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))))
          ]));
}
