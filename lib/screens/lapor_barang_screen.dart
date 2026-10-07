part of '../main.dart';

class LaporBarangScreen extends StatefulWidget {
  final void Function(BarangItem) onLaporanDibuat;
  final String defaultNama;
  const LaporBarangScreen(
      {super.key, required this.onLaporanDibuat, required this.defaultNama});
  @override
  State<LaporBarangScreen> createState() => _LaporBarangScreenState();
}

class _LaporBarangScreenState extends State<LaporBarangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _namaController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _kontakController = TextEditingController();
  JenisLaporan _jenis = JenisLaporan.ditemukan;
  Uint8List? _fotoBytes;
  bool _isPicking = false;

  @override
  void dispose() {
    _namaController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    _kontakController.dispose();
    super.dispose();
  }

  Future<void> _pilihFoto(ImageSource source) async {
    Navigator.pop(context);
    final platform = Theme.of(context).platform;
    final isDesktop = !kIsWeb &&
        (platform == TargetPlatform.windows ||
            platform == TargetPlatform.macOS);
    if (source == ImageSource.camera && isDesktop) {
      _tampilkanPesan(
          'Kamera langsung tersedia di Android/iOS. Pada desktop, pilih foto dari galeri.');
      return;
    }
    setState(() => _isPicking = true);
    try {
      final picked = await _picker.pickImage(
          source: source, imageQuality: 85, maxWidth: 1600);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) setState(() => _fotoBytes = bytes);
      }
    } catch (_) {
      if (mounted) {
        _tampilkanPesan('Kamera/galeri belum dapat diakses di perangkat ini.');
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _bukaPilihanFoto() {
    showModalBottomSheet<void>(
        context: context,
        backgroundColor: UINColors.sand,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        builder: (_) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 22),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Tambahkan foto barang',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: UINColors.deep))),
                  const SizedBox(height: 6),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Pilih sumber foto yang paling nyaman.',
                          style: TextStyle(color: UINColors.muted))),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(
                        child: _SourceButton(
                            icon: Icons.photo_camera_outlined,
                            label: 'Kamera',
                            onTap: () => _pilihFoto(ImageSource.camera))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _SourceButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Galeri',
                            onTap: () => _pilihFoto(ImageSource.gallery)))
                  ])
                ]))));
  }

  void _tampilkanPesan(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message), behavior: SnackBarBehavior.floating));

  void _simpanLaporan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onLaporanDibuat(BarangItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nama: _namaController.text.trim(),
        lokasi: _lokasiController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        jenis: _jenis,
        pelapor: widget.defaultNama,
        kontak: _kontakController.text.trim(),
        tanggal: DateTime.now(),
        fotoBytes: _fotoBytes));
    _namaController.clear();
    _lokasiController.clear();
    _deskripsiController.clear();
    _kontakController.clear();
    setState(() {
      _fotoBytes = null;
      _jenis = JenisLaporan.ditemukan;
    });
    _tampilkanPesan('Laporan berhasil diterbitkan ke warga kampus.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat laporan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const Text('Bantu barang ini pulang',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: UINColors.deep)),
            const SizedBox(height: 5),
            const Text(
                'Lengkapi detail agar mudah ditemukan warga UIN lainnya.',
                style: TextStyle(color: UINColors.muted)),
            const SizedBox(height: 20),
            SegmentedButton<JenisLaporan>(
              segments: const [
                ButtonSegment(
                    value: JenisLaporan.ditemukan,
                    label: Text('Saya menemukan'),
                    icon: Icon(Icons.front_hand_outlined)),
                ButtonSegment(
                    value: JenisLaporan.hilang,
                    label: Text('Saya kehilangan'),
                    icon: Icon(Icons.search_rounded)),
              ],
              selected: {_jenis},
              onSelectionChanged: (value) =>
                  setState(() => _jenis = value.first),
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: _isPicking ? null : _bukaPilihanFoto,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                height: 190,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    color: UINColors.mint,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: _fotoBytes != null
                            ? UINColors.primary
                            : Colors.transparent,
                        width: 2)),
                child: _fotoBytes != null
                    ? Stack(fit: StackFit.expand, children: [
                        Image.memory(_fotoBytes!, fit: BoxFit.cover),
                        Positioned(
                            right: 10,
                            top: 10,
                            child: CircleAvatar(
                                backgroundColor: Colors.white,
                                child: IconButton(
                                    onPressed: () =>
                                        setState(() => _fotoBytes = null),
                                    icon: const Icon(Icons.close,
                                        color: UINColors.coral, size: 19)))),
                      ])
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            _isPicking
                                ? const CircularProgressIndicator(
                                    color: UINColors.primary)
                                : const Icon(Icons.add_a_photo_outlined,
                                    color: UINColors.primary, size: 38),
                            const SizedBox(height: 10),
                            Text(
                                _isPicking
                                    ? 'Membuka pilihan foto...'
                                    : 'Tambahkan foto barang',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: UINColors.deep)),
                            const SizedBox(height: 4),
                            const Text('Kamera atau galeri',
                                style: TextStyle(
                                    color: UINColors.muted, fontSize: 12)),
                          ]),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                    labelText: 'Nama barang',
                    prefixIcon: Icon(Icons.inventory_2_outlined)),
                validator: _wajib),
            const SizedBox(height: 12),
            TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                    labelText: 'Lokasi di kampus',
                    prefixIcon: Icon(Icons.location_on_outlined)),
                validator: _wajib),
            const SizedBox(height: 12),
            TextFormField(
                controller: _deskripsiController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Ciri-ciri dan detail',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true),
                validator: _wajib),
            const SizedBox(height: 12),
            TextFormField(
                controller: _kontakController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp aktif',
                    prefixIcon: Icon(Icons.phone_outlined)),
                validator: _wajib),
            const SizedBox(height: 20),
            SizedBox(
                height: 54,
                child: FilledButton.icon(
                    onPressed: _simpanLaporan,
                    icon: const Icon(Icons.publish_outlined),
                    label: const Text('TERBITKAN LAPORAN',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    style: FilledButton.styleFrom(
                        backgroundColor: UINColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))))),
          ],
        ),
      ),
    );
  }

  String? _wajib(String? value) =>
      value == null || value.trim().isEmpty ? 'Bagian ini wajib diisi' : null;
}
