import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'auth_model.dart';

const _storage = FlutterSecureStorage();
final _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: '741058800173-igmcsupm5kiu5j75p8i0f662l6un8nc6.apps.googleusercontent.com',
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  Future<void> loginWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) throw const ApiException('Login cancelado');

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw const ApiException('Token Google inválido');

    try {
      final res = await _dio.post('/auth/google', data: {'idToken': idToken});
      final tokens = AuthTokens.fromJson(res.data as Map<String, dynamic>);
      await _persistTokens(tokens);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] as String? ?? 'Erro ao autenticar',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> logout() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh != null) {
      try {
        await _dio.post('/auth/logout', data: {'refreshToken': refresh});
      } catch (_) {}
    }
    await _googleSignIn.signOut();
    await _storage.deleteAll();
  }

  Future<void> _persistTokens(AuthTokens tokens) async {
    await _storage.write(key: 'access_token',  value: tokens.accessToken);
    await _storage.write(key: 'refresh_token', value: tokens.refreshToken);
  }
}
