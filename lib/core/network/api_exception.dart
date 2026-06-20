import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    String msg = 'Erro inesperado';
    if (body is Map && body['message'] != null) {
      msg = body['message'] as String;
    } else if (status == 400) {
      msg = 'Requisição inválida';
    } else if (status == 401) {
      msg = 'Sessão expirada';
    } else if (status == 404) {
      msg = 'Item não encontrado';
    }
    return ApiException(msg, statusCode: status);
  }

  @override
  String toString() => message;
}
