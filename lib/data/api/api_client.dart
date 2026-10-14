import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';
import 'token_store.dart';

/// Error with the message the API sends ({"detail": "..."} or field errors).
class ApiException implements Exception {
  ApiException(this.message, {this.status, this.fields = const {}});
  final String message;
  final int? status;
  final Map<String, List<String>> fields;

  @override
  String toString() => message;

  static ApiException from(DioException e) {
    final data = e.response?.data;
    final status = e.response?.statusCode;
    if (data is Map) {
      final fields = <String, List<String>>{};
      String? detail;
      data.forEach((k, v) {
        final list = v is List ? v.map((x) => '$x').toList() : ['$v'];
        if (k == 'detail' || k == 'non_field_errors') {
          detail ??= list.first;
        } else {
          fields['$k'] = list;
        }
      });
      return ApiException(detail ?? (fields.isNotEmpty ? fields.values.first.first : 'Something went wrong'),
          status: status, fields: fields);
    }
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return ApiException('You are offline · we will retry', status: status);
    }
    return ApiException('Something went wrong', status: status);
  }
}

/// Dio with the JWT attached and a one-time refresh on 401.
class ApiClient {
  ApiClient({TokenStore? tokens, Dio? dio})
      : tokens = tokens ?? TokenStore(),
        dio = dio ?? Dio(BaseOptions(baseUrl: Env.apiBaseUrl, connectTimeout: const Duration(seconds: 15))) {
    this.dio.interceptors.add(
          QueuedInterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await this.tokens.access;
              if (token != null && options.extra['auth'] != false) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
            onError: (err, handler) async {
              final retried = err.requestOptions.extra['retried'] == true;
              if (err.response?.statusCode == 401 && !retried && await _refresh()) {
                final opts = err.requestOptions..extra['retried'] = true;
                opts.headers['Authorization'] = 'Bearer ${await this.tokens.access}';
                try {
                  return handler.resolve(await this.dio.fetch(opts));
                } on DioException catch (e) {
                  return handler.next(e);
                }
              }
              handler.next(err);
            },
          ),
        );
  }

  final TokenStore tokens;
  final Dio dio;

  /// Called when refresh fails, so the app can sign out.
  void Function()? onSessionExpired;

  Future<bool> _refresh() async {
    final refresh = await tokens.refresh;
    if (refresh == null) return false;
    try {
      final r = await Dio(BaseOptions(baseUrl: Env.apiBaseUrl)).post('/auth/refresh/', data: {'refresh': refresh});
      await tokens.save(access: r.data['access'] as String, refresh: (r.data['refresh'] ?? refresh) as String);
      return true;
    } on DioException {
      await tokens.clear();
      onSessionExpired?.call();
      return false;
    }
  }

  Future<T> _wrap<T>(Future<Response<dynamic>> Function() call) async {
    try {
      final r = await call();
      return r.data as T;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) => _wrap(() => dio.get(path, queryParameters: query));
  Future<T> post<T>(String path, {Object? data, bool auth = true}) =>
      _wrap(() => dio.post(path, data: data, options: Options(extra: {'auth': auth})));
  Future<T> patch<T>(String path, {Object? data}) => _wrap(() => dio.patch(path, data: data));
  Future<T> put<T>(String path, {Object? data}) => _wrap(() => dio.put(path, data: data));
  Future<void> delete(String path) => _wrap(() => dio.delete(path));

  /// List endpoints are paginated ({count, next, previous, results}); this reads every page.
  Future<List<Map<String, dynamic>>> getAll(String path, {Map<String, dynamic>? query}) async {
    final out = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final data = await get<dynamic>(path, query: {...?query, 'page': page, 'page_size': 200});
      if (data is List) return data.cast<Map<String, dynamic>>();
      out.addAll((data['results'] as List).cast<Map<String, dynamic>>());
      if (data['next'] == null) return out;
      page++;
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
