import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_campus/main.dart';

void main() {
  group('Login dan validasi', () {
    test('AuthService hanya menerima email mahasiswa UIN Malang', () {
      final auth = AuthService();

      expect(
        auth.validateCampusEmail('23123456@student.uin-malang.ac.id'),
        isNull,
      );
      expect(
        auth.validateCampusEmail('mahasiswa@gmail.com'),
        isNotNull,
      );
      expect(auth.validateCampusEmail('nim@student.uin.ac.id'), isNotNull);
      expect(auth.validateCampusEmail(''), 'Email wajib diisi');
    });

    testWidgets('form login menolak email non-kampus', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            onLogin: (_, __, ___) async {},
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Mahasiswa Uji');
      await tester.enterText(fields.at(1), 'mahasiswa@gmail.com');
      await tester.ensureVisible(find.text('MASUK KE TEMU'));
      await tester.tap(find.text('MASUK KE TEMU'));
      await tester.pump();

      expect(
        find.text('Gunakan email resmi mahasiswa: '
            'NIM@student.uin-malang.ac.id'),
        findsOneWidget,
      );
      expect(find.text('Selamat datang kembali'), findsOneWidget);
    });

    testWidgets('login valid menavigasikan pengguna ke dashboard',
        (tester) async {
      var loginCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            onLogin: (email, nim, nama) async {
              loginCalled = email == '23123456@student.uin-malang.ac.id' &&
                  nim == '23123456' &&
                  nama == 'Mahasiswa Uji';
            },
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Mahasiswa Uji');
      await tester.enterText(
        fields.at(1),
        '23123456@student.uin-malang.ac.id',
      );
      await tester.ensureVisible(find.text('MASUK KE TEMU'));
      await tester.tap(find.text('MASUK KE TEMU'));
      await tester.pumpAndSettle();

      expect(loginCalled, isTrue);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Pusat aktivitas kampusmu'), findsOneWidget);
    });
  });
}
