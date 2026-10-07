import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'core/theme/app_theme.dart';
part 'models/app_models.dart';
part 'services/app_services.dart';
part 'services/api_service.dart';
part 'repositories/mock_data_repository.dart';
part 'repositories/local_data_repository.dart';
part 'repositories/app_data_repository.dart';
part 'core/utils/formatters.dart';
part 'widgets/common_widgets.dart';
part 'screens/login_screen.dart';
part 'screens/dashboard_screen.dart';
part 'screens/main_navigation_screen.dart';
part 'screens/jelajah_screen.dart';
part 'screens/detail_barang_screen.dart';
part 'screens/lapor_barang_screen.dart';
part 'screens/chat_screens.dart';
part 'screens/profil_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDataRepository.initialize();
  runApp(const LostAndFoundApp());
}
