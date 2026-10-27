import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_campus/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryDraftService extends ReportDraftService {
  ReportDraft? draft;
  bool saveCalled = false;

  @override
  Future<ReportDraft?> load(String email) async {
    return draft?.email == email ? draft : null;
  }

  @override
  Future<void> save(ReportDraft value) async {
    draft = value;
    saveCalled = true;
  }

  @override
  Future<void> delete(String email) async {
    draft = null;
  }
}

const _email = '23123456@student.uin-malang.ac.id';

ReportDraft _draftUji() => ReportDraft(
      email: _email,
      nama: 'Dompet hitam',
      lokasi: 'Gedung Rektorat',
      deskripsi: 'Ada kartu mahasiswa di dalamnya.',
      kontak: '081234567890',
      jenis: JenisLaporan.hilang,
      updatedAt: DateTime(2026, 10, 26, 10),
    );

void main() {
  group('Pemulihan sesi', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('sesi mahasiswa disimpan dan dipulihkan', () async {
      final auth = AuthService();
      await auth.saveLogin(
        email: _email,
        nim: '23123456',
        nama: 'Mahasiswa Uji',
      );

      final session = await auth.loadSession();

      expect(session, isNotNull);
      expect(session!.role, LoginRole.mahasiswa);
      expect(session.email, _email);
      expect(session.nim, '23123456');
      expect(session.nama, 'Mahasiswa Uji');
    });

    test('sesi admin memerlukan token', () async {
      final auth = AuthService();
      await auth.saveLogin(
        email: 'admin@uin-malang.ac.id',
        nim: 'ADMIN',
        nama: 'Administrator TEMU',
        role: LoginRole.admin,
        adminToken: 'token-uji',
      );

      final session = await auth.loadSession();

      expect(session?.role, LoginRole.admin);
      expect(session?.adminToken, 'token-uji');
    });

    test('clear hanya menghapus data autentikasi dan timer sesi', () async {
      SharedPreferences.setMockInitialValues({
        'user_email': _email,
        'user_nim': '23123456',
        'user_nama': 'Mahasiswa Uji',
        'user_role': 'mahasiswa',
        'waktu_sesi_uin': 42,
        'preferensi_lain': 'tetap ada',
      });

      await AuthService().clear();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_email'), isNull);
      expect(prefs.getString('user_nama'), isNull);
      expect(prefs.getString('user_role'), isNull);
      expect(prefs.getInt('waktu_sesi_uin'), isNull);
      expect(prefs.getString('preferensi_lain'), 'tetap ada');
    });

    testWidgets('AuthGate membuka dashboard dari sesi tersimpan',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthGateScreen(
            loadSession: () async => const AuthSession(
              email: _email,
              nim: '23123456',
              nama: 'Mahasiswa Uji',
              role: LoginRole.mahasiswa,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Mahasiswa Uji'), findsOneWidget);
    });

    testWidgets('AuthGate kembali ke login saat tidak ada sesi',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthGateScreen(loadSession: () async => null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selamat datang kembali'), findsOneWidget);
    });
  });

  group('Pemulihan draft laporan', () {
    testWidgets('draft yang tersimpan mengisi kembali form', (tester) async {
      final service = _MemoryDraftService()..draft = _draftUji();

      await tester.pumpWidget(
        MaterialApp(
          home: LaporBarangScreen(
            email: _email,
            defaultNama: 'Mahasiswa Uji',
            draftService: service,
            onLaporanDibuat: (_) async =>
                const ReportSubmissionResult.uploaded(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Draft laporan dipulihkan. Periksa kembali sebelum diterbitkan.'),
        findsOneWidget,
      );
      expect(find.text('Saya kehilangan'), findsOneWidget);

      Future<String?> fieldText(String label) async {
        final labelFinder = find.text(label);
        await tester.scrollUntilVisible(
          labelFinder,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        final field = find
            .ancestor(of: labelFinder, matching: find.byType(TextFormField))
            .first;
        return tester.widget<TextFormField>(field).controller?.text;
      }

      expect(await fieldText('Nama barang'), 'Dompet hitam');
      expect(await fieldText('Lokasi di kampus'), 'Gedung Rektorat');
      expect(await fieldText('Ciri-ciri dan detail'),
          'Ada kartu mahasiswa di dalamnya.');
      expect(await fieldText('Nomor WhatsApp aktif'), '081234567890');
    });

    testWidgets('perubahan form disimpan otomatis sebagai draft',
        (tester) async {
      final service = _MemoryDraftService();

      await tester.pumpWidget(
        MaterialApp(
          home: LaporBarangScreen(
            email: _email,
            defaultNama: 'Mahasiswa Uji',
            draftService: service,
            onLaporanDibuat: (_) async =>
                const ReportSubmissionResult.uploaded(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> fillField(String label, String value) async {
        final labelFinder = find.text(label);
        await tester.scrollUntilVisible(
          labelFinder,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        final field = find
            .ancestor(of: labelFinder, matching: find.byType(TextFormField))
            .first;
        await tester.enterText(field, value);
      }

      await fillField('Nama barang', 'Dompet hitam');
      await fillField('Lokasi di kampus', 'Gedung Rektorat');
      await fillField(
          'Ciri-ciri dan detail', 'Ada kartu mahasiswa di dalamnya');
      await fillField('Nomor WhatsApp aktif', '081234567890');
      await tester.pump(const Duration(milliseconds: 600));

      expect(service.saveCalled, isTrue);
      expect(service.draft?.nama, 'Dompet hitam');
      expect(service.draft?.lokasi, 'Gedung Rektorat');
      expect(service.draft?.jenis, JenisLaporan.ditemukan);
    });

    testWidgets('draft dihapus setelah laporan berhasil dikirim',
        (tester) async {
      final service = _MemoryDraftService()..draft = _draftUji();

      await tester.pumpWidget(
        MaterialApp(
          home: LaporBarangScreen(
            email: _email,
            defaultNama: 'Mahasiswa Uji',
            draftService: service,
            onLaporanDibuat: (_) async =>
                const ReportSubmissionResult.uploaded(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final submitButton = find.text('TERBITKAN LAPORAN');
      await tester.scrollUntilVisible(
        submitButton,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(service.draft, isNull);
      expect(
        find.text('Laporan berhasil diterbitkan ke warga kampus.'),
        findsOneWidget,
      );
    });

    testWidgets('tombol hapus draft membersihkan form dan penyimpanan',
        (tester) async {
      final service = _MemoryDraftService()..draft = _draftUji();

      await tester.pumpWidget(
        MaterialApp(
          home: LaporBarangScreen(
            email: _email,
            defaultNama: 'Mahasiswa Uji',
            draftService: service,
            onLaporanDibuat: (_) async =>
                const ReportSubmissionResult.uploaded(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus draft'));
      await tester.pumpAndSettle();

      expect(service.draft, isNull);
      final fields =
          tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(fields[0].controller?.text, isEmpty);
      expect(
          find.text('Draft laporan dipulihkan. '
              'Periksa kembali sebelum diterbitkan.'),
          findsNothing);
    });
  });
}
