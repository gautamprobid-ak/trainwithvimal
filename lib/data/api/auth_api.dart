import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// The signed-in user as the API returns it (/auth/me/).
class ApiUser {
  ApiUser.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        email = j['email'] as String,
        fullName = j['full_name'] as String,
        initials = j['initials'] as String,
        role = j['role'] as String,
        emailVerified = j['email_verified'] as bool? ?? false,
        onboarded = j['onboarded'] as bool? ?? false,
        clientProfileId = j['client_profile_id'] as int?,
        trainerProfileId = j['trainer_profile_id'] as int?;

  final int id;
  final String email;
  final String fullName;
  final String initials;
  final String role;
  final bool emailVerified;
  final bool onboarded;
  final int? clientProfileId;
  final int? trainerProfileId;
}

/// Invite link as the join screen sees it.
class InviteInfo {
  InviteInfo.fromJson(Map<String, dynamic> j)
      : code = j['code'] as String,
        state = j['state'] as String,
        trainerName = j['trainer_name'] as String?,
        trainerFirstName = j['trainer_first_name'] as String? ?? 'your coach',
        requiresApproval = j['requires_approval'] as bool? ?? true;

  final String code;

  /// on / off / expired / full
  final String state;
  final String? trainerName;
  final String trainerFirstName;
  final bool requiresApproval;
}

/// /api/v1/auth/* — log in, join from a link, verify email, reset password, devices.
class AuthApi {
  AuthApi(this._c);
  final ApiClient _c;

  Future<ApiUser> _session(Map<String, dynamic> data) async {
    await _c.tokens.save(access: data['access'] as String, refresh: data['refresh'] as String);
    return ApiUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<ApiUser> login(String email, String password) async =>
      _session(await _c.post<Map<String, dynamic>>('/auth/login/', data: {'email': email, 'password': password}, auth: false));

  Future<ApiUser?> restore() async {
    if (await _c.tokens.access == null) return null;
    try {
      return await me();
    } on ApiException {
      return null;
    }
  }

  Future<ApiUser> me() async => ApiUser.fromJson(await _c.get<Map<String, dynamic>>('/auth/me/'));

  Future<void> logout({String? deviceToken}) async {
    final refresh = await _c.tokens.refresh;
    try {
      await _c.post<dynamic>('/auth/logout/', data: {'refresh': refresh, 'device_token': ?deviceToken});
    } finally {
      await _c.tokens.clear();
    }
  }

  Future<InviteInfo> invite(String code) async =>
      InviteInfo.fromJson(await _c.get<Map<String, dynamic>>('/auth/invites/$code/'));

  Future<ApiUser> register({
    required String code,
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async =>
      _session(await _c.post<Map<String, dynamic>>('/auth/register/',
          auth: false,
          data: {'code': code, 'full_name': fullName, 'email': email, 'password': password, 'phone': ?phone}));

  Future<void> resendVerifyEmail() => _c.post<dynamic>('/auth/verify-email/send/');
  Future<ApiUser> confirmEmail(String token) async =>
      _session(await _c.post<Map<String, dynamic>>('/auth/verify-email/confirm/', data: {'token': token}, auth: false));

  Future<void> forgotPassword(String email) => _c.post<dynamic>('/auth/password/forgot/', data: {'email': email}, auth: false);
  Future<ApiUser> resetPassword(String token, String password) async => _session(
      await _c.post<Map<String, dynamic>>('/auth/password/reset/', data: {'token': token, 'password': password}, auth: false));
  Future<void> changePassword(String current, String next) =>
      _c.post<dynamic>('/auth/password/change/', data: {'current_password': current, 'new_password': next});

  Future<void> sendLoginLink(String email) => _c.post<dynamic>('/auth/login-link/', data: {'email': email}, auth: false);
  Future<ApiUser> confirmLoginLink(String token) async =>
      _session(await _c.post<Map<String, dynamic>>('/auth/login-link/confirm/', data: {'token': token}, auth: false));

  Future<void> completeOnboarding() => _c.post<dynamic>('/auth/me/onboarding-complete/');

  Future<void> updatePrefs(Map<String, dynamic> prefs) => _c.patch<dynamic>('/auth/me/', data: prefs);

  Future<void> registerDevice(String token, String platform) =>
      _c.post<dynamic>('/auth/devices/', data: {'token': token, 'platform': platform});
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));
