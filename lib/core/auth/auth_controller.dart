import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_service.dart';
import '../models/app_models.dart';
import '../storage/session_storage.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required this.apiService,
    required ApiClient apiClient,
    required SessionStorage sessionStorage,
  }) : _apiClient = apiClient,
       _sessionStorage = sessionStorage;

  final ApiService apiService;
  final ApiClient _apiClient;
  final SessionStorage _sessionStorage;

  Session? _session;
  bool _booted = false;

  Session? get session => _session;
  bool get isAuthenticated => _session != null;
  bool get booted => _booted;

  Future<void> bootstrap() async {
    _session = await _sessionStorage.loadSession();
    _apiClient.setAccessToken(_session?.token);
    _booted = true;
  }

  Future<void> login({
    required String email,
    required String password,
    required Role role,
  }) async {
    final next = await apiService.login(
      email: email,
      password: password,
      role: role,
    );
    _apiClient.setAccessToken(next.token);
    await _sessionStorage.saveSession(next);
    _session = next;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required Role role,
  }) async {
    final next = await apiService.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    _apiClient.setAccessToken(next.token);
    await _sessionStorage.saveSession(next);
    _session = next;
    notifyListeners();
  }

  Future<void> logout() async {
    _apiClient.setAccessToken(null);
    await _sessionStorage.clearSession();
    _session = null;
    notifyListeners();
  }
}
