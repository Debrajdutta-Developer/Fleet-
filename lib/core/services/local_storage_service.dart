import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to handle persistent local caching and secure storage.
class LocalStorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  LocalStorageService({
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
  })  : _prefs = prefs,
        _secureStorage = secureStorage;

  // --- Shared Preferences Keys ---
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyUserCompanyId = 'user_company_id';
  static const String _keyOfflineUserData = 'offline_user_data';

  // --- Secure Storage Keys ---
  static const String _keyAuthToken = 'secure_auth_token';

  // --- Theme Mode Cache ---
  Future<bool> cacheThemeMode(String mode) async {
    return _prefs.setString(_keyThemeMode, mode);
  }

  String? getCachedThemeMode() {
    return _prefs.getString(_keyThemeMode);
  }

  // --- Company Selection Cache ---
  Future<bool> cacheUserCompanyId(String companyId) async {
    return _prefs.setString(_keyUserCompanyId, companyId);
  }

  String? getCachedUserCompanyId() {
    return _prefs.getString(_keyUserCompanyId);
  }

  Future<bool> clearCachedCompanyId() async {
    return _prefs.remove(_keyUserCompanyId);
  }

  // --- Offline User Data Cache ---
  Future<bool> cacheOfflineUserData(String jsonString) async {
    return _prefs.setString(_keyOfflineUserData, jsonString);
  }

  String? getCachedOfflineUserData() {
    return _prefs.getString(_keyOfflineUserData);
  }

  Future<bool> clearCachedOfflineUserData() async {
    return _prefs.remove(_keyOfflineUserData);
  }

  // --- Secure Authentication Token ---
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: _keyAuthToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return _secureStorage.read(key: _keyAuthToken);
  }

  Future<void> deleteAuthToken() async {
    await _secureStorage.delete(key: _keyAuthToken);
  }

  // --- Clear all caches ---
  Future<void> clearAll() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }
}

/// Provider for LocalStorageService.
/// Since SharedPreferences requires an async initialization, we will initialize it in `main.dart`
/// and override this provider in the [ProviderScope].
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError(
    'localStorageServiceProvider must be overridden in main.dart',
  );
});
