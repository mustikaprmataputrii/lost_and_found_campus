part of '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _namaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  String? _validasiEmail(String? value) =>
      AuthService().validateCampusEmail(value);

  Future<void> _prosesLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final email = _emailController.text.trim().toLowerCase();
    final nim = email.split('@').first;
    final nama = _namaController.text.trim();
    await AppDataRepository().login(email: email, nim: nim, nama: nama);
    await AuthService().saveLogin(email: email, nim: nim, nama: nama);
    if (!mounted) return;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) =>
                DashboardScreen(nim: nim, nama: nama, email: email)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [UINColors.deep, UINColors.primary, Color(0xFF2A8061)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
            child: Column(children: [
              const UinLogo(size: 78),
              const SizedBox(height: 22),
              const Text('TEMU',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8)),
              const SizedBox(height: 4),
              Text('Lost & Found UIN Malang',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .8),
                      fontSize: 14,
                      letterSpacing: .4)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: UINColors.sand,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: .18),
                          blurRadius: 28,
                          offset: const Offset(0, 14))
                    ]),
                child: Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selamat datang kembali',
                            style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: UINColors.deep)),
                        const SizedBox(height: 7),
                        const Text(
                            'Masuk menggunakan identitas resmi civitas UIN Malang.',
                            style:
                                TextStyle(color: UINColors.muted, height: 1.4)),
                        const SizedBox(height: 24),
                        TextFormField(
                            controller: _namaController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                                labelText: 'Nama lengkap',
                                prefixIcon: Icon(Icons.person_outline)),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Nama wajib diisi'
                                    : null),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                                labelText: 'Email kampus',
                                hintText: 'NIM@student.uin-malang.ac.id',
                                prefixIcon: Icon(Icons.alternate_email)),
                            validator: _validasiEmail),
                        const SizedBox(height: 12),
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: UINColors.mint,
                                borderRadius: BorderRadius.circular(14)),
                            child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.verified_user_outlined,
                                      color: UINColors.primary, size: 19),
                                  SizedBox(width: 9),
                                  Expanded(
                                      child: Text(
                                          'Akses hanya untuk email dengan format NIM@student.uin-malang.ac.id.',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: UINColors.deep,
                                              height: 1.35)))
                                ])),
                        const SizedBox(height: 22),
                        SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                                onPressed: _isLoading ? null : _prosesLogin,
                                style: FilledButton.styleFrom(
                                    backgroundColor: UINColors.primary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16))),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Text('MASUK KE TEMU',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: .5)))),
                      ]),
                ),
              ),
              const SizedBox(height: 22),
              Text('Ruang aman untuk menemukan kembali barangmu.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .78),
                      fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}
