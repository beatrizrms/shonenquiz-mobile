import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 10.0.2.2 é o alias do host no emulador Android; em produção passar API_BASE_URL via --dart-define
const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080');
const _storage = FlutterSecureStorage();

Dio createDio() {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(_AuthInterceptor());
  dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: false,
    responseHeader: false,
    responseBody: false,
    error: true,
    logPrint: (obj) => debugPrint('[DIO] $obj'),
  ));
  return dio;
}

final dioProvider = Provider<Dio>((ref) => createDio());

// Callback chamado quando a sessão expira — navegar para login
typedef OnSessionExpired = void Function();
OnSessionExpired? onSessionExpired;

class _AuthInterceptor extends InterceptorsWrapper {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      await _storage.deleteAll();
      onSessionExpired?.call();
    }
    handler.next(err);
  }
}
