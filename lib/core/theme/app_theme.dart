part of '../../main.dart';

class UINColors {
  static const primary = Color(0xFF006B45);
  static const deep = Color(0xFF053B2B);
  static const gold = Color(0xFFC9A227);
  static const sand = Color(0xFFF7F5EE);
  static const mint = Color(0xFFE8F3ED);
  static const ink = Color(0xFF14231D);
  static const muted = Color(0xFF6F7D76);
  static const coral = Color(0xFFD95D45);
}

class LostAndFoundApp extends StatelessWidget {
  const LostAndFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: UINColors.primary).copyWith(
        primary: UINColors.primary,
        secondary: UINColors.gold,
        surface: Colors.white);
    return MaterialApp(
      title: 'Temu UIN Malang',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: UINColors.sand,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
            backgroundColor: UINColors.sand,
            foregroundColor: UINColors.deep,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
                color: UINColors.deep,
                fontSize: 19,
                fontWeight: FontWeight.w800)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.black.withValues(alpha: .06))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: UINColors.primary, width: 1.5)),
          labelStyle: const TextStyle(color: UINColors.muted),
        ),
        cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22))),
      ),
      home: const LoginScreen(),
    );
  }
}
