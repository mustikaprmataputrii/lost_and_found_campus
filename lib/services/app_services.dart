part of '../../main.dart';

enum LoginRole { mahasiswa, admin }

class AuthService {
  static const _emailKey = 'user_email';
  static const _nimKey = 'user_nim';
  static const _namaKey = 'user_nama';
  static const _roleKey = 'user_role';
  static const _adminTokenKey = 'admin_token';
  static const _sessionSecondsKey = 'waktu_sesi_uin';

  static final RegExp campusEmailPattern =
      RegExp(r'^\d+@student\.uin-malang\.ac\.id$');

  String? validateCampusEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    final email = value.trim().toLowerCase();
    if (!campusEmailPattern.hasMatch(email)) {
      return 'Gunakan email resmi mahasiswa: NIM@student.uin-malang.ac.id';
    }
    return null;
  }

  Future<void> saveLogin({
    required String email,
    required String nim,
    required String nama,
    LoginRole role = LoginRole.mahasiswa,
    String? adminToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email.trim().toLowerCase());
    await prefs.setString(_nimKey, nim.trim());
    await prefs.setString(_namaKey, nama.trim());
    await prefs.setString(_roleKey, role.name);
    if (adminToken == null) {
      await prefs.remove(_adminTokenKey);
    } else {
      await prefs.setString(_adminTokenKey, adminToken);
    }
  }

  Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey)?.trim().toLowerCase() ?? '';
    final nama = prefs.getString(_namaKey)?.trim() ?? '';
    if (email.isEmpty || nama.isEmpty) return null;

    LoginRole? role;
    final roleName = prefs.getString(_roleKey);
    for (final item in LoginRole.values) {
      if (item.name == roleName) {
        role = item;
        break;
      }
    }
    role ??= (prefs.getString(_adminTokenKey) ?? '').isEmpty
        ? LoginRole.mahasiswa
        : LoginRole.admin;

    if (role == LoginRole.admin) {
      final token = prefs.getString(_adminTokenKey)?.trim() ?? '';
      if (token.isEmpty) return null;
      return AuthSession(
        email: email,
        nim: prefs.getString(_nimKey)?.trim() ?? 'ADMIN',
        nama: nama,
        role: LoginRole.admin,
        adminToken: token,
      );
    }

    if (validateCampusEmail(email) != null) return null;
    return AuthSession(
      email: email,
      nim: prefs.getString(_nimKey)?.trim() ?? email.split('@').first,
      nama: nama,
      role: LoginRole.mahasiswa,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    // Jangan memakai prefs.clear(): draft dan preferensi lain yang tidak
    // terkait autentikasi harus tetap tersedia setelah pengguna logout.
    await Future.wait([
      prefs.remove(_emailKey),
      prefs.remove(_nimKey),
      prefs.remove(_namaKey),
      prefs.remove(_roleKey),
      prefs.remove(_adminTokenKey),
      prefs.remove(_sessionSecondsKey),
    ]);
  }
}

class SessionService {
  Future<int?> loadSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('waktu_sesi_uin');
  }

  Future<void> saveSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('waktu_sesi_uin', seconds);
  }
}
