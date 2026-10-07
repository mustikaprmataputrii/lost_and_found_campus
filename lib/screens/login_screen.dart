part of '../main.dart';

enum _LoginMode { mahasiswa, admin }

class LoginScreen extends StatefulWidget {
  final Future<void> Function(String email, String nim, String nama)? onLogin;
  final Future<AdminLoginResult> Function(String email, String password)?
      onAdminLogin;

  const LoginScreen({super.key, this.onLogin, this.onAdminLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _namaController = TextEditingController();
  final _passwordController = TextEditingController();
  _LoginMode _mode = _LoginMode.mahasiswa;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _namaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validasiEmail(String? value) => _mode == _LoginMode.admin
      ? (value == null || value.trim().isEmpty
          ? 'Email admin wajib diisi'
          : null)
      : AuthService().validateCampusEmail(value);

  String? _validasiPassword(String? value) =>
      value == null || value.isEmpty ? 'Password admin wajib diisi' : null;

  Future<void> _prosesLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final email = _emailController.text.trim().toLowerCase();
    try {
      if (_mode == _LoginMode.admin) {
        final result = widget.onAdminLogin != null
            ? await widget.onAdminLogin!(email, _passwordController.text)
            : await AppDataRepository()
                .adminLogin(email: email, password: _passwordController.text);
        await AuthService().saveLogin(
            email: result.email,
            nim: 'ADMIN',
            nama: result.nama,
            role: LoginRole.admin,
            adminToken: result.token);
        if (!mounted) return;
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => AdminDashboardScreen(
                    adminEmail: result.email,
                    adminName: result.nama,
                    adminToken: result.token)));
      } else {
        final nim = email.split('@').first;
        final nama = _namaController.text.trim();
        if (widget.onLogin != null) {
          await widget.onLogin!(email, nim, nama);
        } else {
          await AppDataRepository().login(email: email, nim: nim, nama: nama);
          await AuthService().saveLogin(
              email: email, nim: nim, nama: nama, role: LoginRole.mahasiswa);
        }
        if (!mounted) return;
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    DashboardScreen(nim: nim, nama: nama, email: email)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                        Text(
                            _mode == _LoginMode.admin
                                ? 'Portal admin TEMU'
                                : 'Selamat datang kembali',
                            style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: UINColors.deep)),
                        const SizedBox(height: 7),
                        Text(
                            _mode == _LoginMode.admin
                                ? 'Kelola laporan dan aktivitas warga kampus.'
                                : 'Masuk menggunakan identitas resmi civitas UIN Malang.',
                            style: const TextStyle(
                                color: UINColors.muted, height: 1.4)),
                        const SizedBox(height: 24),
                        if (_mode == _LoginMode.mahasiswa)
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
                        if (_mode == _LoginMode.mahasiswa)
                          const SizedBox(height: 14),
                        TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                                labelText: _mode == _LoginMode.admin
                                    ? 'Email admin'
                                    : 'Email kampus',
                                hintText: _mode == _LoginMode.admin
                                    ? 'admin@uin-malang.ac.id'
                                    : 'NIM@student.uin-malang.ac.id',
                                prefixIcon: const Icon(Icons.alternate_email)),
                            validator: _validasiEmail),
                        if (_mode == _LoginMode.admin) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                  labelText: 'Password admin',
                                  prefixIcon: Icon(Icons.lock_outline)),
                              validator: _validasiPassword),
                        ],
                        const SizedBox(height: 12),
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: UINColors.mint,
                                borderRadius: BorderRadius.circular(14)),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.verified_user_outlined,
                                      color: UINColors.primary, size: 19),
                                  const SizedBox(width: 9),
                                  Expanded(
                                      child: Text(
                                          _mode == _LoginMode.admin
                                              ? 'Akses admin diverifikasi oleh server TEMU.'
                                              : 'Akses hanya untuk email dengan format NIM@student.uin-malang.ac.id.',
                                          style: const TextStyle(
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
                                    : Text(
                                        _mode == _LoginMode.admin
                                            ? 'MASUK SEBAGAI ADMIN'
                                            : 'MASUK KE TEMU',
                                         style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: .5)))),
                      ]),
                ),
              ),
              const SizedBox(height: 22),
              TextButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _mode = _mode == _LoginMode.mahasiswa
                                ? _LoginMode.admin
                                : _LoginMode.mahasiswa;
                            _formKey.currentState?.reset();
                          }),
                  icon: Icon(_mode == _LoginMode.admin
                      ? Icons.school_outlined
                      : Icons.admin_panel_settings_outlined),
                  label: Text(_mode == _LoginMode.admin
                      ? 'Kembali ke login mahasiswa'
                      : 'Masuk sebagai admin'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white)),
              const SizedBox(height: 4),
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
