import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the JWT pair in the platform keychain / keystore.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;

  static const _access = 'twv_access';
  static const _refresh = 'twv_refresh';

  Future<String?> get access => _s.read(key: _access);
  Future<String?> get refresh => _s.read(key: _refresh);

  Future<void> save({required String access, required String refresh}) async {
    await _s.write(key: _access, value: access);
    await _s.write(key: _refresh, value: refresh);
  }

  Future<void> clear() async {
    await _s.delete(key: _access);
    await _s.delete(key: _refresh);
  }
}
