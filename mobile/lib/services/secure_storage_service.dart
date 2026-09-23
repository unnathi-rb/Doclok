import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage so token handling lives in one place.
/// On Android this uses the Keystore; nothing is ever written in plain text.
class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';

  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  static Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  static Future<void> clearAccessToken() =>
      _storage.delete(key: _accessTokenKey);
}
