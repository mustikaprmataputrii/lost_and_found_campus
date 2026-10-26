part of '../main.dart';

class AuthGateScreen extends StatefulWidget {
  final Future<AuthSession?> Function()? loadSession;

  const AuthGateScreen({super.key, this.loadSession});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  late final Future<AuthSession?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = widget.loadSession?.call() ?? AuthService().loadSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthSession?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SessionSplashScreen();
        }
        if (snapshot.hasError) {
          debugPrint('Gagal memulihkan sesi: ${snapshot.error}');
          return const LoginScreen();
        }

        final session = snapshot.data;
        if (session == null) return const LoginScreen();
        if (session.isAdmin) {
          final token = session.adminToken?.trim() ?? '';
          if (token.isEmpty) return const LoginScreen();
          return AdminDashboardScreen(
            adminEmail: session.email,
            adminName: session.nama,
            adminToken: token,
          );
        }
        return DashboardScreen(
          nim: session.nim,
          nama: session.nama,
          email: session.email,
        );
      },
    );
  }
}

class _SessionSplashScreen extends StatelessWidget {
  const _SessionSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [UINColors.deep, UINColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UinLogo(size: 78),
                SizedBox(height: 22),
                Text(
                  'TEMU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
                SizedBox(height: 28),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: UINColors.gold,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Memulihkan sesi...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
