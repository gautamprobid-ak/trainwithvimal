import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_api.dart';
import 'env.dart';

/// Firebase Cloud Messaging: asks permission (Permissions screen) and sends
/// this device's token to the API so the backend can push to it.
class PushService {
  PushService(this._auth);
  final AuthApi _auth;
  bool _ready = false;

  static Future<void> init() async {
    if (!Env.firebase) return;
    await Firebase.initializeApp();
  }

  /// Call after the user taps "Allow notifications".
  Future<bool> requestAndRegister() async {
    if (!Env.firebase) return false;
    final m = FirebaseMessaging.instance;
    final s = await m.requestPermission();
    if (s.authorizationStatus == AuthorizationStatus.denied) return false;
    final token = await m.getToken();
    if (token == null) return false;
    if (Env.useApi) await _auth.registerDevice(token, _platform);
    if (!_ready) {
      m.onTokenRefresh.listen((t) => Env.useApi ? _auth.registerDevice(t, _platform) : null);
      _ready = true;
    }
    return true;
  }

  String get _platform => kIsWeb
      ? 'web'
      : switch (defaultTargetPlatform) {
          TargetPlatform.iOS => 'ios',
          _ => 'android',
        };
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref.watch(authApiProvider)));
