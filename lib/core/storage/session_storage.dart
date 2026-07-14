import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_models.dart';

class SessionStorage {
  SessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'hr_session';

  final FlutterSecureStorage _storage;

  Future<Session?> loadSession() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return Session.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(Session session) {
    return _storage.write(key: _key, value: session.encode());
  }

  Future<void> clearSession() {
    return _storage.delete(key: _key);
  }
}
