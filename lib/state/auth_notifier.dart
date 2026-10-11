import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

@immutable
class AppUser {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final bool active;
  const AppUser(
      {required this.id,
      required this.username,
      required this.email,
      required this.fullName,
      required this.role,
      required this.active});
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
      id: (j['id'] as num).toInt(),
      username: '${j['username'] ?? ''}',
      email: '${j['email'] ?? ''}',
      fullName: '${j['fullName'] ?? j['username'] ?? ''}',
      role: '${j['role'] ?? 'customer'}',
      active: j['active'] != false);
  int get level => switch (role) { 'admin' => 3, 'manager' => 2, _ => 1 };
  String get roleLabel => switch (role) {
        'admin' => 'Администратор',
        'manager' => 'Менеджер',
        _ => 'Покупатель'
      };
}

class AuthNotifier extends ChangeNotifier {
  static const _accessKey = 'pet_auth_access_token';
  static const _refreshKey = 'pet_auth_refresh_token';
  static const _lastActivityKey = 'pet_auth_last_activity';
  static const _startedAtKey = 'pet_auth_started_at';
  static const _displayRoleKey = 'pet_auth_display_role';
  final SharedPreferences prefs;
  late final Dio dio;
  AppUser? _user;
  String? _access;
  String? _refresh;
  bool restoring = true;
  bool busy = false;
  String? sessionMessage;
  DateTime? _lastActivity;
  DateTime? _startedAt;
  bool _refreshing = false;
  String?
      _displayRole; // Только отображение интерфейса; серверные права не зависят от этого значения.
  AppUser? get user => _user;
  String? get accessToken => _access;
  String? get refreshToken => _refresh;
  String get displayRoleLabel => switch (_displayRole ?? _user?.role) {
        'admin' => 'Администратор',
        'manager' => 'Менеджер',
        _ => 'Покупатель'
      };
  bool get isAuthenticated => _user != null && _access != null;
  DateTime? get lastActivity => _lastActivity;
  bool hasRole(String role) =>
      _user != null &&
      _roleLevel(_displayRole ?? _user!.role) >=
          switch (role) { 'admin' => 3, 'manager' => 2, _ => 1 };
  static int _roleLevel(String role) =>
      switch (role) { 'admin' => 3, 'manager' => 2, _ => 1 };
  bool hasAnyRole(List<String> roles) =>
      _user != null && roles.contains(_user!.role);

  AuthNotifier(this.prefs) {
    dio = buildDio(tokenProvider: () => _access);
    _installRefreshInterceptor();
  }

  Future<void> restore() async {
    _access = prefs.getString(_accessKey);
    _refresh = prefs.getString(_refreshKey);
    _displayRole = prefs.getString(_displayRoleKey);
    final last = prefs.getInt(_lastActivityKey);
    final start = prefs.getInt(_startedAtKey);
    if (last != null) _lastActivity = DateTime.fromMillisecondsSinceEpoch(last);
    if (start != null) _startedAt = DateTime.fromMillisecondsSinceEpoch(start);
    if (_access != null) {
      try {
        final r = await dio.get('auth/me',
            options: Options(extra: {'skipAuthRefresh': true}));
        _user = AppUser.fromJson(Map<String, dynamic>.from(r.data as Map));
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 && _refresh != null) {
          try {
            await refreshTokens();
            final r = await dio.get('auth/me');
            _user = AppUser.fromJson(Map<String, dynamic>.from(r.data as Map));
          } catch (_) {
            await _clearSession('Сессия истекла. Войдите снова.');
          }
        } else if (e.response?.statusCode == 401) {
          await _clearSession('Сессия истекла. Войдите снова.');
        }
      } catch (_) {/* При временной сетевой ошибке токены сохраняем. */}
    }
    restoring = false;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    busy = true;
    notifyListeners();
    try {
      final r = await dio.post('auth/login',
          data: {'username': username.trim(), 'password': password},
          options: Options(extra: {'skipAuthRefresh': true}));
      await _saveTokens(Map<String, dynamic>.from(r.data as Map));
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> register(
      {required String username,
      required String password,
      required String email,
      required String fullName}) async {
    busy = true;
    notifyListeners();
    try {
      await dio.post('auth/register',
          data: {
            'username': username.trim(),
            'password': password,
            'email': email.trim(),
            'fullName': fullName.trim()
          },
          options: Options(extra: {'skipAuthRefresh': true}));
      await login(username, password);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> data,
      {bool newSession = true}) async {
    _access = '${data['accessToken']}';
    _refresh = '${data['refreshToken']}';
    _user = AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    if (newSession) {
      _lastActivity = DateTime.now();
      _startedAt = DateTime.now();
    }
    _lastActivity ??= DateTime.now();
    _startedAt ??= DateTime.now();
    _displayRole = _user!.role;
    await prefs.setString(_accessKey, _access!);
    await prefs.setString(_refreshKey, _refresh!);
    await prefs.setString(_displayRoleKey, _displayRole!);
    await prefs.setInt(_lastActivityKey, _lastActivity!.millisecondsSinceEpoch);
    await prefs.setInt(_startedAtKey, _startedAt!.millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> refreshTokens() async {
    if (_refreshing) {
      final previousAccess = _access;
      for (var i = 0; i < 30 && _refreshing; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (_access != null && _access != previousAccess) return;
      throw StateError('Обновление сессии не удалось');
    }
    final token = _refresh;
    if (token == null) throw StateError('Нет refresh token');
    _refreshing = true;
    try {
      final r = await dio.post('auth/refresh',
          data: {'refreshToken': token},
          options: Options(extra: {'skipAuthRefresh': true}));
      await _saveTokens(Map<String, dynamic>.from(r.data as Map),
          newSession: false);
    } catch (_) {
      await _clearSession('Не удалось обновить сессию. Выполнен выход.');
      rethrow;
    } finally {
      _refreshing = false;
    }
  }

  void _installRefreshInterceptor() {
    dio.interceptors.add(InterceptorsWrapper(onError: (e, handler) async {
      final request = e.requestOptions;
      if (e.response?.statusCode != 401 ||
          request.path.contains('auth/') ||
          request.extra['skipAuthRefresh'] == true ||
          request.extra['retriedAfterRefresh'] == true ||
          _refresh == null) {
        handler.next(e);
        return;
      }
      try {
        await refreshTokens();
        request.extra['retriedAfterRefresh'] = true;
        request.headers['Authorization'] = 'Bearer $_access';
        final response = await dio.fetch(request);
        handler.resolve(response);
      } catch (_) {
        handler.next(e);
      }
    }));
  }

  void recordActivity() {
    if (!isAuthenticated) return;
    _lastActivity = DateTime.now();
    prefs.setInt(_lastActivityKey, _lastActivity!.millisecondsSinceEpoch);
  }

  Duration? get inactivityRemaining {
    if (_lastActivity == null) return null;
    return const Duration(minutes: 3) -
        DateTime.now().difference(_lastActivity!);
  }

  Duration? get sessionRemaining {
    if (_startedAt == null) return null;
    return const Duration(hours: 8) - DateTime.now().difference(_startedAt!);
  }

  Future<void> logout({String? message}) async {
    try {
      if (_access != null) {
        await dio.post('auth/logout',
            data: {'refreshToken': _refresh},
            options: Options(
                receiveTimeout: const Duration(seconds: 2),
                extra: {'skipAuthRefresh': true}));
      }
    } catch (_) {}
    await _clearSession(message);
  }

  Future<void> _clearSession(String? message) async {
    _user = null;
    _access = null;
    _refresh = null;
    _displayRole = null;
    _lastActivity = null;
    _startedAt = null;
    sessionMessage = message;
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_displayRoleKey);
    await prefs.remove(_lastActivityKey);
    await prefs.remove(_startedAtKey);
    notifyListeners();
  }

  Future<Map<String, dynamic>> loadStats() async {
    final r = await dio.get('admin/stats');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<List<AppUser>> loadUsers() async {
    final r = await dio.get('admin/users');
    return (r.data['items'] as List)
        .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> updateUser({required int id, String? role, bool? active}) async {
    await dio.patch('admin/users', data: {
      'id': id,
      if (role != null) 'role': role,
      if (active != null) 'active': active
    });
  }
}
