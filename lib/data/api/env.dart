/// Build-time switches.
///
///   flutter run --dart-define=USE_API=true --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
///
/// Without USE_API the app runs fully on the design's mock data.
abstract final class Env {
  static const useApi = bool.fromEnvironment('USE_API');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000/api/v1');

  /// Turn on after adding google-services.json / GoogleService-Info.plist (see README).
  static const firebase = bool.fromEnvironment('FIREBASE');
}
