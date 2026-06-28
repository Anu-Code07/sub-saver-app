import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subsaver/core/constants/app_constants.dart';
import 'package:subsaver/features/authentication/data/models/user_model.dart';
import 'package:subsaver/features/authentication/domain/entities/user_entity.dart';

/// Persists verified user sessions until the app is uninstalled.
class SessionStorageService {
  SessionStorageService(this._prefs);

  static const _sessionKey = 'trusted_user_session';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> hasTrustedSession() async {
    final raw = await _secureStorage.read(key: _sessionKey);
    return raw != null && raw.isNotEmpty;
  }

  Future<UserEntity?> readTrustedUser() async {
    final raw = await _secureStorage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTrustedUser(UserEntity user) async {
    final model = user is UserModel
        ? user
        : UserModel(
            id: user.id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            avatar: user.avatar,
            upiId: user.upiId,
            preferredPaymentMethod: user.preferredPaymentMethod,
            isPremium: user.isPremium,
            createdAt: user.createdAt,
          );
    await _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(model.toJson()),
    );
  }

  Future<void> clearTrustedSession() async {
    await _secureStorage.delete(key: _sessionKey);
    await _prefs.remove(AppConstants.biometricEnabledKey);
  }

  bool isBiometricEnabled() =>
      _prefs.getBool(AppConstants.biometricEnabledKey) ?? false;

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.biometricEnabledKey, enabled);
  }
}
