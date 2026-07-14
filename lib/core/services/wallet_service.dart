import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WalletService extends ChangeNotifier {
  WalletService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _keyBalance = 'mock_wallet_balance';
  static const _keyLastReset = 'mock_wallet_last_reset';
  static const _keySettled = 'mock_wallet_settled_preds';

  int _balance = 10000000;
  int get balance => _balance;

  Future<void> init() async {
    final balanceStr = await _storage.read(key: _keyBalance);
    if (balanceStr != null) {
      _balance = int.tryParse(balanceStr) ?? 10000000;
    } else {
      _balance = 10000000;
      await _storage.write(key: _keyBalance, value: _balance.toString());
    }

    final lastResetStr = await _storage.read(key: _keyLastReset);
    DateTime lastReset;
    if (lastResetStr != null) {
      lastReset = DateTime.tryParse(lastResetStr) ?? DateTime.now();
    } else {
      lastReset = DateTime.now();
      await _storage.write(key: _keyLastReset, value: lastReset.toIso8601String());
    }

    if (_balance < 100000) {
      final daysSince = DateTime.now().difference(lastReset).inDays;
      if (daysSince >= 3) {
        _balance = 10000000;
        await _storage.write(key: _keyBalance, value: _balance.toString());
        await _storage.write(key: _keyLastReset, value: DateTime.now().toIso8601String());
      }
    }

    notifyListeners();
  }

  Future<void> deductBalance(int amount) async {
    if (_balance >= amount) {
      _balance -= amount;
      await _storage.write(key: _keyBalance, value: _balance.toString());
      notifyListeners();
    }
  }

  Future<void> addBalance(int amount) async {
    _balance += amount;
    await _storage.write(key: _keyBalance, value: _balance.toString());
    notifyListeners();
  }

  Future<List<String>> getSettledPredictionIds() async {
    final raw = await _storage.read(key: _keySettled);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> markPredictionAsSettled(String predictionId) async {
    final settled = await getSettledPredictionIds();
    if (!settled.contains(predictionId)) {
      settled.add(predictionId);
      await _storage.write(key: _keySettled, value: jsonEncode(settled));
    }
  }
}
