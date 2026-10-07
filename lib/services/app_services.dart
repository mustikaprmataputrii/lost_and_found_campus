part of '../../main.dart';

enum LoginRole { mahasiswa, admin }

class AuthService {
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
    await prefs.setString('user_email', email);
    await prefs.setString('user_nim', nim);
    await prefs.setString('user_nama', nama);
    await prefs.setString('user_role', role.name);
    if (adminToken == null) {
      await prefs.remove('admin_token');
    } else {
      await prefs.setString('admin_token', adminToken);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
