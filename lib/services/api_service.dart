part of '../main.dart';

class ApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8088/api/index.php';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8088/api/index.php';
    }
    return 'http://127.0.0.1:8088/api/index.php';
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse(ApiConfig.baseUrl).replace(
      queryParameters: {
        'path': path,
        ...?query,
      },
    );
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['error'] : null;
      final errorMessage =
          message ?? 'API request failed (${response.statusCode})';
      throw ApiException(response.statusCode, '$errorMessage');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Response API tidak valid.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String nim,
    required String nama,
  }) async {
    final response = await _client
        .post(
          _uri('auth/login'),
          headers: _headers,
          body: jsonEncode({'email': email, 'nim': nim, 'nama': nama}),
        )
        .timeout(const Duration(seconds: 5));
    return _decode(response);
  }

  Future<AdminLoginResult> adminLogin({
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          _uri('auth/admin-login'),
          headers: _headers,
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 5));
    return AdminLoginResult.fromMap(await _decode(response));
  }

  Future<void> updatePresence({
    required String email,
    required bool isOnline,
  }) async {
    final response = await _client
        .post(
          _uri('presence'),
          headers: _headers,
          body: jsonEncode({'email': email, 'isOnline': isOnline}),
        )
        .timeout(const Duration(seconds: 5));
    await _decode(response);
  }

  Future<String> startChat({
    required String email,
    required String reportId,
  }) async {
    final response = await _client
        .post(
          _uri('chats/start'),
          headers: _headers,
          body: jsonEncode({'email': email, 'reportId': reportId}),
        )
        .timeout(const Duration(seconds: 8));
    final decoded = await _decode(response);
    return '${(decoded['data'] as Map)['chatId']}';
  }

  Future<void> sendMessage({
    required String email,
    required String chatId,
    required String text,
  }) async {
    final response = await _client
        .post(
          _uri('messages/send'),
          headers: _headers,
          body: jsonEncode({'email': email, 'chatId': chatId, 'text': text}),
        )
        .timeout(const Duration(seconds: 8));
    await _decode(response);
  }

  Future<void> deleteMessage({
    required String email,
    required String messageId,
  }) async {
    final response = await _client
        .delete(_uri('messages', {'email': email, 'id': messageId}))
        .timeout(const Duration(seconds: 8));
    await _decode(response);
  }

  Future<void> requestClaim({
    required String email,
    required String reportId,
  }) async {
    final response = await _client
        .post(
          _uri('claims/request'),
          headers: _headers,
          body: jsonEncode({'email': email, 'reportId': reportId}),
        )
        .timeout(const Duration(seconds: 8));
    await _decode(response);
  }

  Future<void> respondToClaim({
    required String email,
    required String reportId,
    required bool approve,
  }) async {
    final response = await _client
        .post(
          _uri('claims/respond'),
          headers: _headers,
          body: jsonEncode({
            'email': email,
            'reportId': reportId,
            'approve': approve,
          }),
        )
        .timeout(const Duration(seconds: 8));
    await _decode(response);
  }

  Future<void> markChatRead({
    required String email,
    required String chatId,
  }) async {
    final response = await _client
        .post(
          _uri('chats/read'),
          headers: _headers,
          body: jsonEncode({'email': email, 'chatId': chatId}),
        )
        .timeout(const Duration(seconds: 8));
    await _decode(response);
  }

  Future<void> markNotificationsRead({required String email}) async {
    final response = await _client
        .post(
          _uri('notifications/read-all'),
          headers: _headers,
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 8));
    await _decode(response);
  }

  Future<void> deleteReport({
    required String email,
    required String reportId,
  }) async {
    final response = await _client
        .delete(_uri('reports', {'email': email, 'id': reportId}))
        .timeout(const Duration(seconds: 5));
    await _decode(response);
  }

  Future<LocalDataSnapshot> load({required String email}) async {
    final response = await _client
        .get(_uri('sync', {'email': email}))
        .timeout(const Duration(seconds: 5));
    final decoded = await _decode(response);
    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    final reports = (data['reports'] as List? ?? [])
        .map((item) =>
            BarangItem.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList();
    final chats = (data['chats'] as List? ?? [])
        .map(
            (item) => SesiChat.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList();
    final notifications = (data['notifications'] as List? ?? [])
        .map((item) =>
            NotifikasiItem.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList();

    return LocalDataSnapshot(
      reports: reports,
      chats: chats,
      notifications: notifications,
    );
  }

  Future<LocalDataSnapshot> loadAdmin({required String token}) async {
    final response = await _client.get(
      _uri('admin/sync'),
      headers: {..._headers, 'X-Admin-Token': token},
    ).timeout(const Duration(seconds: 5));
    final decoded = await _decode(response);
    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    final reports = (data['reports'] as List? ?? [])
        .map((item) =>
            BarangItem.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList();
    final chats = (data['chats'] as List? ?? [])
        .map(
            (item) => SesiChat.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList();
    final notifications = (data['notifications'] as List? ?? [])
        .map((item) =>
            NotifikasiItem.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList();
    final users = (data['users'] as List? ?? [])
        .map((item) =>
            AdminUser.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList();
    return LocalDataSnapshot(
      reports: reports,
      chats: chats,
      notifications: notifications,
      users: users,
    );
  }

  Future<void> updateAdminUser({
    required String token,
    required String currentEmail,
    required String nim,
    required String email,
    required String nama,
  }) async {
    final response = await _client
        .post(
          _uri('admin/users/update'),
          headers: {..._headers, 'X-Admin-Token': token},
          body: jsonEncode({
            'currentEmail': currentEmail,
            'nim': nim,
            'email': email,
            'nama': nama,
          }),
        )
        .timeout(const Duration(seconds: 8));
    await _decode(response);
  }

  Future<void> deleteAdminUser({
    required String token,
    required String email,
  }) async {
    final response = await _client
        .post(
          _uri('admin/users/delete'),
          headers: {..._headers, 'X-Admin-Token': token},
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 8));
    await _decode(response);
  }

  Future<void> saveAll({
    required String email,
    required String nama,
    required List<BarangItem> reports,
    required List<SesiChat> chats,
    required List<NotifikasiItem> notifications,
  }) async {
    final response = await _client
        .post(
          _uri('sync'),
          headers: _headers,
          body: jsonEncode({
            'email': email,
            'nama': nama,
            'reports': reports.map((item) => item.toMap()).toList(),
            'chats': chats.map((item) => item.toMap()).toList(),
            'notifications': notifications.map((item) => item.toMap()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 8));
    await _decode(response);
  }
}
