import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  bool isDemoMode = false;

  ApiService._() {
    final baseUrl = (!kIsWeb && (Platform.isAndroid))
        ? AppConstants.apiBaseUrl
        : AppConstants.apiBaseUrlDesktop;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('API Error: ${error.requestOptions.path} — ${error.message}');
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get(path, queryParameters: queryParams);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  /// POST with application/x-www-form-urlencoded content type.
  /// Required for OAuth2PasswordRequestForm endpoints like /auth/login.
  Future<Response> postForm(String path, Map<String, String> fields) {
    return _dio.post(
      path,
      data: fields.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&'),
      options: Options(
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ),
    );
  }

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<void> setToken(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: AppConstants.tokenKey);

  Future<void> clearToken() => _storage.delete(key: AppConstants.tokenKey);
}
